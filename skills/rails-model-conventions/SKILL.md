---
name: rails-model-conventions
description: Use when creating or modifying Rails models, adding associations, defining scopes, extracting concerns, or designing data interfaces
---

# Rails Model Conventions

Models own data relationships, validations, scopes, and query interfaces. Business logic lives in interactors, not models.

## Core Principles

1. **Data layer, not logic layer** — Models define associations, validations, scopes, and data access. Business logic (multi-step operations, side effects, notifications) belongs in interactors
2. **Clean interfaces** — Expose intent-based methods, hide implementation
3. **Message passing** — Ask objects, don't reach into their associations
4. **Pass objects, not IDs** — Method signatures accept domain objects (in-process calls)
5. **Compose with concerns** — Extract shared behavior into concerns
6. **State records over booleans** — `has_one :closure` not `closed: boolean` for audit trail

## Engine Models

Engine models live in isolated namespaces with explicit table names:

```ruby
# engines/operations/app/models/operations/application_record.rb
module Operations
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
  end
end

# engines/operations/app/models/operations/goal.rb
module Operations
  class Goal < ApplicationRecord
    self.table_name = 'operations_goals'

    belongs_to :account
    belongs_to :parent, class_name: 'Operations::Goal', optional: true
    has_many :children, class_name: 'Operations::Goal', foreign_key: :parent_id
    has_one :metric, dependent: :destroy
    has_many :observations, through: :metric

    scope :for_account, ->(account) { where(account: account) }
    scope :active, -> { where(archived_at: nil) }
    scope :company_visible, -> { where(company_visible: true) }
  end
end
```

Key rules for engine models:
- Always set `self.table_name = 'engine_prefix_table_name'`
- Use full class names for self-referential or cross-engine associations
- Inherit from the engine's `ApplicationRecord`, not the main app's

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

## Organization

Order within a model file:

1. Constants
2. `self.table_name` (if engine model)
3. Associations (`belongs_to`, `has_many`, etc.)
4. Validations
5. Scopes
6. Callbacks (use sparingly)
7. Public methods
8. Private methods

## Soft Delete

Engine models use `archived_at` timestamp:

```ruby
scope :active, -> { where(archived_at: nil) }
scope :archived, -> { where.not(archived_at: nil) }

def archive!
  update!(archived_at: Time.current)
end
```

Main app models may use the `paranoia` gem (`acts_as_paranoid`). Follow whichever pattern the model already uses.

## Brownfield Reality

The main app has fat models with many concerns (e.g., Account includes 32 concerns). When modifying these:
- Follow the existing patterns within that model
- Don't refactor concern composition unless explicitly asked
- For new behavior on existing models, prefer extracting a concern over adding methods directly
- For new multi-step operations, use interactors — don't add complex methods to the model

## Quick Reference

| Do | Don't |
|----|-------|
| Associations, validations, scopes | Multi-step business logic in models |
| `user.bookmark(academy)` | `user.bookmarks.create(...)` from outside |
| `self.table_name` in engine models | Rely on Rails table name inference in engines |
| Concerns for shared behavior | All logic in one file |
| `has_one :closure` for state | `closed: boolean` column |
| Interactors for operations | Callbacks with side effects |
| Counter cache | `.count` on associations |

## Common Mistakes

1. **Business logic in models** — Multi-step operations, notifications, and side effects belong in interactors
2. **Leaking implementation** — Provide clean interface methods
3. **Missing table_name in engines** — Engine models MUST set `self.table_name` explicitly
4. **Callback hell** — Especially callbacks that trigger external side effects (emails, APIs, jobs)
5. **N+1 queries** — Use counter_cache, includes, eager loading
6. **Fat model additions** — When adding to an existing fat model, extract a concern

**Remember:** Models are the data layer. Interactors are the logic layer.
