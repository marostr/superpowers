---
name: rails-policy-conventions
description: Use when creating or modifying Pundit policies in app/policies
---

# Rails Policy Conventions

Conventions for Pundit authorization policies in this project.

## When to Use This Skill

Automatically activates when working on:
- `app/policies/**/*.rb`

Use this skill when:
- Creating new policies
- Adding authorization methods
- Modifying permission logic

## Core Principle: Permission Only

Policies answer ONE question: **"Is this user allowed to attempt this action?"**

They don't know or care if the action will succeed. That's the model's job.

**WRONG** - Policy checking resource state:
```ruby
def publish?
  user.admin? && !record.published?  # State check doesn't belong here
end
```

**RIGHT** - Policy checks permission only:
```ruby
def publish?
  content_creator_or_above?  # Permission only
end

# State validation belongs in the model
class Article < ApplicationRecord
  def publish!
    raise "Already published" if published?
    update!(published_at: Time.current)
  end
end
```

## Role Hierarchy

Use the established helper methods from ApplicationPolicy:

```ruby
# Available helpers (defined in ApplicationPolicy)
company_user?              # user.is_a?(CompanyUser)
mentor?                    # company_user? && user.mentor?
content_creator?           # company_user? && user.content_creator?
company_admin?             # company_user? && user.company_admin?
mentor_or_above?           # mentor? || content_creator? || company_admin?
content_creator_or_above?  # content_creator? || company_admin?
```

## Controller Enforcement (Critical)

Every controller action that accesses a resource MUST call `authorize`:

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    authorize @article  # REQUIRED - no exceptions
  end

  def create
    @article = Article.new(article_params)
    authorize @article  # Authorize before save
    @article.save!
  end
end
```

## Policy Structure

```ruby
class ArticlePolicy < ApplicationPolicy
  def index?
    true  # Or appropriate permission check
  end

  def show?
    true
  end

  def create?
    mentor_or_above?
  end

  def update?
    owner? || content_creator_or_above?
  end

  def destroy?
    company_admin?
  end

  private

  def owner?
    record.author == user
  end
end
```

## Quick Reference

| Do | Don't |
|----|-------|
| Check user permissions | Check resource state |
| Use role helper methods | Complex inline role checks |
| `authorize @resource` in every action | Skip authorization |
| Return boolean only | Raise errors in policies |
| Inherit from ApplicationPolicy | Duplicate role helper logic |
| Keep policies thin | Business logic in policies |
| Block in policy AND controller; controller handles redirect UX | Permit in policy but block in controller |

## Method Naming

Match controller actions:
- `index?`, `show?`, `create?`, `new?`, `update?`, `edit?`, `destroy?`
- Custom actions get `?` suffix: `publish?`, `archive?`, `duplicate?`

## Scopes (Optional)

When filtering collections, define in Scope class:

```ruby
class Scope < ApplicationPolicy::Scope
  def resolve
    if user.company_admin?
      scope.all
    else
      scope.where(author: user)
    end
  end
end
```

Usage: `policy_scope(Article)` - but this is optional, not required.

## Testing Policies

**Authorization tests belong in policy specs, NOT in request/controller specs.**

Policy specs are fast unit tests. Request specs should use authorized users (happy path) and never mock policies.

## Common Mistakes

1. **State checks in policies** - Policies check permissions, models check state
2. **Missing authorize calls** - Every action needs authorization
3. **Bypassing role helpers** - Use `mentor_or_above?` not inline checks
4. **Business logic** - Policies only answer "is this allowed?"
5. **Raising exceptions** - Return true/false, let Pundit handle errors
6. **Testing authorization in request specs** - Move to policy specs
7. **Mocking policies in tests** - Use real authorized users instead

**Remember:** Policies are gatekeepers, not validators. They check WHO, not WHAT or WHEN.
