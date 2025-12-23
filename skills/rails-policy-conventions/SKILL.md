---
name: rails-policy-conventions
description: Use when creating or modifying Pundit policies in app/policies
---

# Rails Policy Conventions

Conventions for Pundit authorization policies in this project.

## Core Principle: Permission Only

Policies answer ONE question: **"Is this user allowed to attempt this action?"**

They don't care if the action will succeed. That's the model's job.

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

Use helpers from ApplicationPolicy:

```ruby
mentor_or_above?           # mentor? || content_creator? || company_admin?
content_creator_or_above?  # content_creator? || company_admin?
```

## Controller Enforcement

Every action MUST call `authorize`:

```ruby
def show
  @article = Article.find(params[:id])
  authorize @article  # REQUIRED - no exceptions
end
```

## Quick Reference

| Do | Don't |
|----|-------|
| Check user permissions | Check resource state |
| Use role helper methods | Complex inline role checks |
| `authorize @resource` in every action | Skip authorization |
| Return boolean only | Raise errors in policies |
| Keep policies thin | Business logic in policies |

## Testing

**Authorization tests belong in policy specs, NOT request specs.**

Policy specs are fast unit tests. Request specs use authorized users (happy path) and never mock policies.

## Common Mistakes

1. **State checks in policies** - Policies check permissions, models check state
2. **Missing authorize calls** - Every action needs authorization
3. **Bypassing role helpers** - Use `mentor_or_above?` not inline checks
4. **Testing auth in request specs** - Move to policy specs

**Remember:** Policies are gatekeepers, not validators. They check WHO, not WHAT or WHEN.
