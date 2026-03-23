---
name: rails-testing-conventions
description: Use when creating or modifying RSpec tests — request, model, policy, serializer, interactor, or query specs
---

# Rails Testing Conventions

Tests verify behavior, not implementation. Real data, real objects, pristine output.

## Core Principles

1. **Never test mocked behavior** — If you mock it, you're not testing it
2. **No mocks in integration tests** — Request specs use real data. WebMock for external APIs only
3. **Pristine test output** — Capture and verify expected errors, don't let them pollute output
4. **All failures are your responsibility** — Even pre-existing. Never ignore failing tests
5. **Coverage cannot decrease** — Never delete a failing test, fix the root cause

## Spec Types

| Type | Location | Use For |
|------|----------|---------|
| Request | `spec/requests/` | JSON:API endpoints — single action CRUD, response shape, status codes |
| Model | `spec/models/` | Associations, validations, scopes, data methods |
| Policy | `spec/policies/` | ALL authorization tests — permissions and scopes |
| Serializer | `spec/serializers/` | JSON:API output shape, attributes, relationships, meta |
| Interactor | `spec/interactors/` | Business logic — perform, success/failure, rollback |
| Query | `spec/queries/` | Filtering logic, return correct subsets |

## Request Specs (JSON:API)

```ruby
RSpec.describe 'Operations::Api::Goals' do
  let(:account) { create(:active_account_with_finished_onboarding) }
  let(:user) { create(:billing_user, account:) }

  before do
    allow_any_instance_of(Account).to receive(:operations_engine_enabled?).and_return(true)
    host!(account.app_domain)
    default_url_options[:account_slug] = account.slug
    sign_in(user)
  end

  describe 'GET /operations/api/goals' do
    it 'returns goals for the current user' do
      goal = create(:operations_goal, account:)
      create(:operations_goal_owner, goal:, user:)

      get api_goals_url, xhr: true

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'][0]['attributes']['title']).to eq(goal.title)
    end
  end

  describe 'POST /operations/api/goals' do
    it 'creates a goal via organizer' do
      params = { data: { attributes: { title: 'Q1 Revenue', target_date: '2026-06-30' } } }

      expect { post api_goals_url, params:, xhr: true }
        .to change(Operations::Goal, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
```

Key patterns:
- `host!` and `default_url_options[:account_slug]` for multi-tenancy
- `sign_in(user)` for authentication
- Feature gate stub: `allow_any_instance_of(Account).to receive(:operations_engine_enabled?).and_return(true)`
- `xhr: true` for AJAX requests
- Parse response body and assert JSON:API structure

## Interactor Specs

```ruby
RSpec.describe Operations::Goals::CreateGoalOrganizer do
  let(:account) { create(:active_account_with_finished_onboarding) }
  let(:user) { create(:billing_user, account:) }
  let(:params) { { title: 'Q1 Revenue', target_date: '2026-06-30' } }

  describe '#perform' do
    context 'when valid' do
      it 'creates goal and associated records' do
        result = described_class.perform(params:, account:, user:)

        expect(result).to be_success
        expect(result.goal).to be_persisted
        expect(result.metric).to be_persisted
      end

      it 'creates all expected records' do
        expect { described_class.perform(params:, account:, user:) }
          .to change(Operations::Goal, :count).by(1)
          .and change(Operations::Metric, :count).by(1)
          .and change(Operations::GoalOwner, :count).by(1)
      end
    end

    context 'when invalid' do
      let(:params) { { title: nil } }

      it 'returns failure and rolls back all records' do
        result = described_class.perform(params:, account:, user:)

        expect(result).to be_failure
        expect(Operations::Goal.count).to eq(0)
        expect(Operations::Metric.count).to eq(0)
      end
    end
  end
end
```

Key patterns:
- Test `result.success?` and `result.failure?`
- Verify context outputs are set (`result.goal`, `result.metric`)
- Test transactional rollback on failure — all-or-nothing
- Test with `change` matchers for record counts

## Policy Specs

```ruby
RSpec.describe Operations::GoalPolicy do
  let(:account) { create(:active_account_with_finished_onboarding) }
  let(:goal) { create(:operations_goal, account:) }

  describe 'permissions' do
    context 'as billing admin' do
      let(:user) { create(:billing_user, account:) }

      it { expect(described_class.new(user, goal)).to permit_actions(:show, :update, :destroy) }
    end

    context 'as goal owner' do
      let(:user) { create(:company_user, account:) }
      before { create(:operations_goal_owner, goal:, user:) }

      it { expect(described_class.new(user, goal)).to permit_actions(:show, :update) }
      it { expect(described_class.new(user, goal)).to forbid_action(:destroy) }
    end
  end

  describe 'scope' do
    let(:user) { create(:company_user, account:) }
    let(:owned_goal) { create(:operations_goal, account:) }
    let(:other_goal) { create(:operations_goal, account:) }

    before { create(:operations_goal_owner, goal: owned_goal, user:) }

    it 'returns only visible goals' do
      scope = described_class::Scope.new(user, Operations::Goal).resolve
      expect(scope).to include(owned_goal)
      expect(scope).not_to include(other_goal)
    end
  end
end
```

Key patterns:
- Use `pundit-matchers` (`permit_actions`, `forbid_action`)
- Test scope resolution separately
- Test each role level

## Serializer Specs

```ruby
RSpec.describe Operations::GoalSerializer do
  let(:goal) { create(:operations_goal, :with_metric) }
  let(:user) { create(:billing_user, account: goal.account) }

  it 'serializes expected attributes' do
    json = described_class.new(goal, params: { current_user: user }).serializable_hash

    expect(json[:data][:attributes]).to include(:title, :description, :target_date)
    expect(json[:data][:relationships]).to include(:metric, :owners, :watchers)
  end

  it 'includes permissions in meta' do
    json = described_class.new(goal, params: { current_user: user }).serializable_hash

    expect(json[:data][:meta]).to include(:can_edit, :can_delete)
  end
end
```

## Factory Rules

- **Explicit attributes** — `create(:billing_user, account:)` not `create(:user)`
- **Use traits** — `:with_metric`, `:archived` for variations
- **`let` by default** — `let!` only when record must exist before test
- **Create in final state** — No `update!` in before blocks

## Engine Test Setup

Every engine request spec needs:
```ruby
before do
  allow_any_instance_of(Account).to receive(:operations_engine_enabled?).and_return(true)
  host!(account.app_domain)
  default_url_options[:account_slug] = account.slug
  sign_in(user)
end
```

## Quick Reference

| Do | Don't |
|----|-------|
| Test real behavior | Test mocked behavior |
| WebMock for external APIs | Mock internal classes |
| Explicit factory attributes | Rely on factory defaults |
| `let` by default | `let!` everywhere |
| Auth tests in policy specs | Auth tests in request specs |
| Test interactor success AND failure | Only test happy path |
| Test transactional rollback | Assume rollback works |
| Feature gate stub in engine specs | Skip feature gate setup |
| `xhr: true` for AJAX requests | Forget xhr flag |

## Common Mistakes

1. **Testing mocks** — You're testing nothing
2. **Auth in request specs** — Move to policy specs
3. **Missing feature gate stub** — Engine specs need the stub or they 404
4. **Not testing rollback** — Verify failure rolls back ALL records
5. **Missing xhr: true** — JSON:API endpoints expect XHR requests
6. **Incomplete interactor specs** — Test both success and failure paths

**Remember:** Tests verify behavior, not implementation. Interactor specs test the full organizer flow. Policy specs own authorization. Request specs own the API shape.
