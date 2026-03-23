---
name: rails-policy-conventions
description: Use when creating or modifying Pundit authorization policies, defining role-based permissions, adding scopes, or implementing visibility rules
---

# Rails Policy Conventions

Policies answer one question: "Is this user allowed to attempt this action?" They check WHO, not WHAT or WHEN.

## Core Principles

1. **Permission only** — Check if the user may attempt the action, not if it will succeed
2. **Scope is mandatory** — Every policy MUST define a `Scope` class for index filtering
3. **Thin policies** — No business logic, no state checks. Return booleans only
4. **Test in policy specs** — Authorization tests belong in `spec/policies/`, NOT request specs

## Permission, Not State

```ruby
# WRONG - checking state
def publish?
  user.admin? && !record.published?  # State check doesn't belong here
end

# RIGHT - permission only
def publish?
  billing_admin_permission?
end
```

## Scope Classes

Every policy MUST define a `Scope` class. Scopes control what records a user can see:

```ruby
module Operations
  class GoalPolicy < ::ApplicationPolicy
    class Scope < Scope
      def resolve
        return scope.for_account(user.account) if user.billing_admin_permission?

        scope.for_account(user.account).where(id: visible_goal_ids)
      end

      private

      def visible_goal_ids
        [
          *owned_goal_ids,
          *user_watched_goal_ids,
          *group_watched_goal_ids,
          *managed_report_goal_ids,
          *company_visible_goal_ids
        ].uniq
      end

      def owned_goal_ids
        Operations::GoalOwner.where(user: user).select(:goal_id)
      end

      def company_visible_goal_ids
        scope.company_visible.select(:id)
      end
    end
  end
end
```

Controllers use `policy_scope` for index actions:
```ruby
def index
  @resources = policy_scope(Operations::Goal)
end
```

## Role Hierarchy

Trainual has a role hierarchy with helper methods on `ApplicationPolicy`:

```ruby
# Available in all policies:
billing_admin_permission?      # Billing admin — full account access
# Additional role checks depend on the domain:
# - Goal owner, watcher, manager (Operations)
# - Content creator, mentor (main app)
```

For engine policies, visibility often depends on multiple relationships:

```ruby
def show?
  billing_admin_permission? ||
    record.owner?(user) ||
    record.watcher?(user) ||
    (record.company_visible? && same_account?)
end

def update?
  billing_admin_permission? || record.owner?(user)
end

def destroy?
  billing_admin_permission? || record.created_by?(user)
end
```

## Engine Policies

Engine policies inherit from `::ApplicationPolicy` (main app base):

```ruby
module Operations
  class GoalPolicy < ::ApplicationPolicy
    # Always prefix with :: to reference main app

    def show?
      visible_to_user?
    end

    def update?
      can_manage_goal?
    end

    private

    def visible_to_user?
      billing_admin_permission? ||
        record.owner?(user) ||
        record.watcher?(user)
    end

    def can_manage_goal?
      billing_admin_permission? || record.owner?(user)
    end
  end
end
```

## Quick Reference

| Do | Don't |
|----|-------|
| Check user permissions | Check resource state |
| Define `Scope` class on every policy | Skip scope (breaks index) |
| `policy_scope` for index actions | Manual `.where` filtering in controllers |
| `billing_admin_permission?` | Inline admin checks |
| Inherit `::ApplicationPolicy` in engines | Skip the `::` prefix |
| Return boolean only | Raise errors or return messages |
| Test in `spec/policies/` | Test auth in request specs |

## Common Mistakes

1. **Missing Scope class** — Every policy needs one, even if it's `scope.all`
2. **State checks in policies** — Policies check permissions, models check state
3. **Missing scope in index** — Use `policy_scope`, not `Model.all`
4. **Testing auth in request specs** — Move to policy specs
5. **Complex visibility without helper methods** — Extract to private methods for readability
6. **Forgetting `::` prefix in engine policies** — `::ApplicationPolicy` not `ApplicationPolicy`

**Remember:** Policies are gatekeepers, not validators. They check WHO, not WHAT or WHEN. Scopes are mandatory.
