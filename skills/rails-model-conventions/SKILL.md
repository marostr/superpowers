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
5. **Compose with concerns** - Break complex models into focused, namespaced concerns
6. **State records over booleans** - Track state changes with separate models, not columns

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

## Concern Composition (Critical)

Break complex models into focused concerns with namespaced directories:

```
app/models/
  card.rb                    # Just includes + core associations
  card/
    closeable.rb             # Closure state logic
    golden.rb                # Gold/featured logic
    postponable.rb           # Not-now state logic
    searchable.rb            # Search indexing
    taggable.rb              # Tag associations
```

**Model includes concerns explicitly:**
```ruby
class Card < ApplicationRecord
  include Closeable, Golden, Postponable, Searchable, Taggable,
          Assignable, Attachable, Broadcastable, Eventable
  # Core associations only - everything else in concerns
  belongs_to :board
  belongs_to :column, optional: true
end
```

**Each concern is focused and self-contained:**
```ruby
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy
    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }
  end

  def closed?
    closure.present?
  end

  def close(user: Current.user)
    transaction do
      create_closure!(user: user) unless closed?
      track_event :closed, creator: user
    end
  end

  def reopen(user: Current.user)
    transaction do
      closure&.destroy!
      track_event :reopened, creator: user
    end
  end
end
```

## State Records Pattern

Instead of boolean columns, use separate models that track who and when:

**WRONG** - Boolean columns:
```ruby
# Migration: add_column :cards, :closed, :boolean
# Migration: add_column :cards, :closed_at, :datetime
# Migration: add_column :cards, :closed_by_id, :uuid

card.update!(closed: true, closed_at: Time.current, closed_by: user)
```

**RIGHT** - State records:
```ruby
# Separate model tracks the state
class Closure < ApplicationRecord
  belongs_to :card
  belongs_to :user  # Who closed it
  # created_at = when it was closed
end

# Card has_one :closure - presence means closed
card.create_closure!(user: current_user)
```

**Benefits:**
- Full audit trail (who, when, can add why)
- Clean scopes: `Card.closed` = `joins(:closure)`
- Toggle by create/destroy, not update
- Easy to add metadata (reason, notes)

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
| `Card::Closeable` concern | All logic in card.rb |
| `has_one :closure` for state | `closed: boolean` column |
| `card.close(user:)` | `card.update!(closed: true)` |
| `scope :closed, -> { joins(:closure) }` | `scope :closed, -> { where(closed: true) }` |
| `user.bookmark(academy)` | `user.bookmarks.create(...)` |
| Intent-based method names | Exposing associations directly |

## Common Mistakes

1. **God models** - Break into focused concerns with namespaced directories
2. **Boolean state columns** - Use state records for audit trail
3. **Anemic models** - Business logic belongs in models, not controllers
4. **Leaking implementation** - Provide clean interface methods
5. **Callback hell** - Prefer explicit method calls
6. **N+1 queries** - Use counter_cache, includes, eager loading
