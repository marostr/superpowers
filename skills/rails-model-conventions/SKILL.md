---
name: rails-model-conventions
description: Use when creating or modifying Rails models in app/models
---

# Rails Model Conventions

Conventions for Rails models in this project.

## Core Principles

1. **Business logic lives here** - Models own ALL domain logic, not controllers
2. **Clean interfaces** - Don't leak implementation details
3. **Message passing** - Ask objects, don't reach into their associations
4. **Pass objects, not IDs** - Method signatures should accept domain objects

## Clean Interfaces (Critical)

```ruby
# WRONG - leaking implementation
user.bookmarks.where(academy: academy).exists?
user.bookmarks.create!(academy: academy)

# RIGHT - clean interface
user.bookmarked?(academy)
user.bookmark(academy)

# Model exposes intent-based methods
class User < ApplicationRecord
  def bookmarked?(academy)
    academy_bookmarks.exists?(academy: academy)
  end

  def bookmark(academy)
    academy_bookmarks.find_or_create_by(academy: academy)
  end
end
```

## Organization

Order: constants → associations → validations → scopes → callbacks → public methods → private methods

## Guidelines

- **Validations** - Use built-in validators, validate at model level
- **Associations** - Use `:dependent`, `:inverse_of`, counter caches
- **Scopes** - Named scopes for reusable queries
- **Callbacks** - Use sparingly, never for external side effects (emails, APIs)
- **Queries** - Never raw SQL, use ActiveRecord/Arel. Avoid N+1 with `includes`

## Quick Reference

| Do | Don't |
|----|-------|
| `user.bookmark(academy)` | `user.bookmarks.create(...)` |
| `academy.enrolled?(student)` | `academy.enrollments.exists?(...)` |
| Intent-based method names | Exposing associations directly |
| Counter cache | `.count` on associations |
| `:inverse_of` on associations | Bidirectional without inverse |

## Common Mistakes

1. **Anemic models** - Business logic belongs in models, not controllers
2. **Leaking implementation** - Provide clean interface methods
3. **Callback hell** - Prefer explicit method calls
4. **N+1 queries** - Use counter_cache, includes, eager loading
5. **View logic in models** - Display formatting belongs in ViewComponents
