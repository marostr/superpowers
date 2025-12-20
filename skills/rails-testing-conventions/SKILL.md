---
name: rails-testing-conventions
description: Use when creating or modifying RSpec tests in spec/
---

# Rails Testing Conventions

Conventions for RSpec tests in this project.

## When to Use This Skill

Automatically activates when working on:
- `spec/**/*_spec.rb`

Use this skill when:
- Writing new tests
- Modifying existing tests
- Debugging test failures
- Setting up test data

## Core Principles (Non-Negotiable)

### 1. Never Test Mocked Behavior

If you mock it, you're not testing it. Mocks verify integration points, not behavior.

```ruby
# WRONG - you tested nothing
allow(user).to receive(:admin?).and_return(true)
expect(user.admin?).to eq(true)

# RIGHT - test actual behavior
user = create(:company_user, role: :company_admin)
expect(user.admin?).to eq(true)
```

### 2. No Mocks in Integration Tests

Request and system specs use real data, real models. WebMock for external services only.

```ruby
# WRONG - mocking in integration test
allow(PaymentGateway).to receive(:charge).and_return(success)

# RIGHT - use WebMock for external APIs
stub_request(:post, 'https://api.stripe.com/v1/charges')
  .to_return(status: 200, body: { id: 'ch_123' }.to_json)
```

### 3. Pristine Test Output

No "expected" noise. If a test expects an error, capture and verify it.

```ruby
# WRONG - error pollutes output
it "raises error" do
  expect { thing.explode! }.to raise_error
end

# RIGHT - capture and verify
it "raises InvalidState error" do
  expect { thing.explode! }.to raise_error(InvalidStateError, /cannot explode/)
end
```

### 4. All Failures Are Your Responsibility

Even pre-existing failures. Broken windows theory applies. Never ignore a failing test.

### 5. Coverage Cannot Decrease

Undercover enforces this in CI. Never delete a test because it's failing - fix the root cause.

## Spec Types

### Request Specs (`spec/requests/`)

Integration tests for **small features** - single controller, single action.

**Critical Rules:**
- **Never test authorization logic here** - that belongs in policy specs
- **Never mock policies** - use real authorized users (happy path)
- **Test functional behavior only** - CRUD operations, redirects, flash messages
- **Index actions must assert rendered content** - verify at least one record displays to avoid false positives

### System Specs (`spec/system/`)

Integration tests for **multi-step flows** - spans multiple controllers/actions.

```ruby
RSpec.describe 'Code Review Flow', :js do
  let(:reviewer) { create(:company_user, role: :mentor) }
  let(:review) { create(:code_review, :pending) }

  before { sign_in reviewer }

  it 'completes full review cycle' do
    visit code_review_path(review)

    click_on 'Start Review'
    fill_in 'Comment', with: 'Looks good'
    click_on 'Approve'

    expect(page).to have_text('Review completed')
  end
end
```

**System spec rules:**
- Wait for elements, never `sleep`
- Use `have_text`, `have_selector` (Capybara waits automatically)
- Use `data-testid` for stable selectors when needed

### Model Specs (`spec/models/`)

Public interface + Shoulda matchers for declarative stuff.

```ruby
RSpec.describe User do
  # Shoulda for declarations
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_many(:memberships) }

  # Behavior tests for public methods
  describe '#bookmarked?' do
    it 'returns true when academy is bookmarked' do
      user = create(:user)
      academy = create(:academy)
      create(:academy_bookmark, user: user, academy: academy)

      expect(user.bookmarked?(academy)).to be true
    end
  end
end
```

### Policy Specs (`spec/policies/`)

**This is where ALL authorization tests belong** - not in request specs.

Test permission logic with Pundit matchers. Cover each role. These are fast unit tests.

**Key points:**
- Test each role that should have access
- Test each role that should NOT have access
- Use `permissions` block to test multiple actions at once

### Component Specs (`spec/components/`)

ViewComponent rendering tests.

```ruby
RSpec.describe AlertComponent, type: :component do
  it 'renders message' do
    render_inline(described_class.new(message: 'Warning!', type: :warning))

    expect(page).to have_text('Warning!')
    expect(page).to have_selector('.alert-warning')
  end
end
```

## Factory Conventions

### Explicit - No Hidden Defaults

```ruby
# WRONG - relies on factory defaults
let(:user) { create(:user) }

# RIGHT - explicit about what matters
let(:mentor) { create(:company_user, company: company, role: :mentor) }
let(:published_academy) { create(:academy, :published, company: company) }
```

### Use Traits for Variations

```ruby
# Factory definition
factory :academy do
  name { Faker::Company.name }
  company

  trait :published do
    published_at { Time.current }
  end

  trait :draft do
    published_at { nil }
  end
end

# Usage
create(:academy, :published)
create(:academy, :draft)
```

### `let` vs `let!`

```ruby
# let - lazy, use by default
let(:user) { create(:user) }

# let! - eager, only when record must exist before test runs
let!(:existing_record) { create(:record) }  # For "finds existing" tests

# build when persistence not needed
let(:user) { build(:user) }  # Faster, no DB hit
```

### Create in Proper State - No Updates in Before Blocks

Create objects in their final state rather than creating then updating. Each `update!` is an extra SQL query that slows down specs. Pass attributes directly to `create()` instead of updating in `before` blocks.

## External APIs

**WebMock stubs only** - explicit and reviewable.

```ruby
before do
  stub_request(:post, 'https://api.stripe.com/v1/charges')
    .to_return(status: 200, body: { id: 'ch_123' }.to_json)
end
```

**Mock at integration boundaries only:**

```ruby
# WRONG - mocking the thing you're testing
allow(order).to receive(:total).and_return(100)

# RIGHT - mock at external boundary
stub_request(:get, 'https://pricing.api/rates').to_return(...)
```

## Quick Reference

| Do | Don't |
|----|-------|
| Test real behavior | Test mocked behavior |
| WebMock for external APIs | Mock internal classes in integration tests |
| Explicit factory attributes | Rely on factory defaults |
| Create in final state | Update in before blocks |
| `let` by default | `let!` everywhere |
| Capture expected errors | Let errors pollute output |
| Wait for elements | Use `sleep` |
| Request spec for single action | System spec for everything |
| System spec for multi-step flows | Request spec for complex flows |
| Assert content in index tests | Only check HTTP status |

## Common Mistakes

1. **Testing mocks** - You're testing nothing
2. **Mocking in integration tests** - Defeats the purpose
3. **Mocking policies** - Never mock policies, use real authorized users
4. **Authorization tests in request specs** - Move to policy specs (fast unit tests)
5. **Implicit factory defaults** - Reader can't understand test
6. **Updates in before blocks** - Create objects in final state, extra queries slow specs
7. **`sleep` in system specs** - Use Capybara's built-in waiting
8. **Ignoring failures** - All failures are your responsibility
9. **Deleting failing tests** - Fix the root cause
10. **Index tests without content assertions** - Always verify at least one record is rendered

**Remember:** Tests verify behavior, not implementation. If you can swap the implementation without changing tests, you're testing right.
