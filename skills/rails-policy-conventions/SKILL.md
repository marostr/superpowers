---
name: rails-policy-conventions
description: Use when creating or modifying Pundit authorization policies, defining role-based permissions, or adding authorize calls
---

# Rails Policy Conventions

Policies answer one question: "Is this user allowed to attempt this action?" They check WHO, not WHAT or WHEN.

## Core Principles

1. **Permission only** - Check if the user may attempt the action, not if it will succeed
2. **Use role helpers** - `mentor_or_above?`, `content_creator_or_above?` from ApplicationPolicy
3. **Thin policies** - No business logic, no state checks. Return booleans only
4. **Test in policy specs** - Authorization tests belong in `spec/policies/`, NOT request specs

## Permission, Not State

```ruby
# WRONG - checking state
def publish?
  user.admin? && !record.published?  # State check doesn't belong here
end

# RIGHT - permission only
def publish?
  content_creator_or_above?
end
```

## Role Hierarchy

```ruby
mentor_or_above?           # mentor? || content_creator? || company_admin?
content_creator_or_above?  # content_creator? || company_admin?
```

## Quick Reference

| Do | Don't |
|----|-------|
| Check user permissions | Check resource state |
| Use role helper methods | Complex inline role checks |
| `authorize @resource` in every action | Skip authorization |
| Return boolean only | Raise errors in policies |
| Keep policies thin | Business logic in policies |

## Common Mistakes

1. **State checks in policies** - Policies check permissions, models check state
2. **Missing authorize calls** - Every controller action needs authorization
3. **Bypassing role helpers** - Use `mentor_or_above?` not inline checks
4. **Testing auth in request specs** - Move to policy specs

**Remember:** Policies are gatekeepers, not validators. They check WHO, not WHAT or WHEN.
