---
name: rails-controller-conventions
description: Use when creating or modifying Rails controllers, adding actions, setting up authorization, configuring routes, or handling Turbo responses
---

# Rails Controller Conventions

Controllers are thin request handlers. They authorize, delegate to models, and respond — nothing more.

## Core Principles

1. **Thin controllers** - No business logic. Delegate to models
2. **Authorize everything** - Every action MUST call `authorize`. No exceptions
3. **Message passing** - Ask objects, don't reach into their internals (see `rails-model-conventions`)
4. **RESTful** - 7 standard actions, one controller per resource
5. **CRUD for state** - `resource :closure` not `post :close`. Create enables, destroy disables
6. **Hotwire/Turbo only** - Never write API/JSON response code
7. **No exception control flow** - Let exceptions propagate
8. **No raw SQL** - ActiveRecord query methods or Arel only

## Authorization

Every controller action MUST call `authorize` to enforce Pundit policies.

```ruby
def create
  @article = Article.new(article_params)
  authorize @article                    # BEFORE performing the action
  @article.save!
  redirect_to @article
end

def index
  authorize Article                     # Class, not instance
  @articles = policy_scope(Article)
end
```

- `[:companies, resource]` for namespaced policies
- `index`/`new`: authorize the class (no instance yet)
- Actions with instances: authorize the instance

## Quick Reference

| Do | Don't |
|----|-------|
| `resource :closure` | `post :close, :reopen` |
| `authorize @resource` in every action | Skip authorization |
| `user.bookmarked?(academy)` | `user.bookmarks.exists?(...)` |
| Model methods for state | Inline association queries |
| Turbo Streams | JSON responses |
| 7 RESTful actions | Custom action proliferation |

## Common Mistakes

1. **Missing authorize calls** - Every action MUST call `authorize`
2. **Checking state in views** - Move to model method
3. **Business logic in controller** - Move to model
4. **respond_to with json** - Use turbo_stream only
5. **Catching exceptions for control flow** - Let exceptions propagate
6. **Fat actions** - Extract to model methods

**Remember:** Controllers authorize and delegate. Everything else belongs in models.
