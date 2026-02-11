---
name: rails-model-conventions
description: Use when creating or modifying Rails models, adding domain logic, defining associations, extracting concerns, or designing query interfaces
---

# Rails Model Conventions

Models own all domain logic. They provide clean interfaces and hide implementation details.

## Core Principles

1. **Business logic lives here** - Models own ALL domain logic, not controllers
2. **Clean interfaces** - Expose intent-based methods, hide implementation
3. **Message passing** - Ask objects, don't reach into their associations
4. **Pass objects, not IDs** - Method signatures accept domain objects
5. **Compose with concerns** - Namespaced concerns: `Card::Closeable` in `card/closeable.rb`
6. **State records over booleans** - `has_one :closure` not `closed: boolean` for audit trail

## Clean Interfaces

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

Sender sends message to Receiver. Receiver performs action or returns data. Sender never reaches into Receiver's internal structure.

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
| `Card::Closeable` in `card/closeable.rb` | All logic in `card.rb` |
| `has_one :closure` for state | `closed: boolean` column |
| `user.bookmark(academy)` | `user.bookmarks.create(...)` |
| Intent-based method names | Exposing associations directly |
| Counter cache | `.count` on associations |

## Common Mistakes

1. **Anemic models** - Business logic belongs in models, not controllers
2. **Leaking implementation** - Provide clean interface methods
3. **Callback hell** - Prefer explicit method calls
4. **N+1 queries** - Use counter_cache, includes, eager loading
5. **View logic in models** - Display formatting belongs in ViewComponents

**Remember:** Models are the domain. Rich interfaces, hidden implementation.
