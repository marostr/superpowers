---
name: rails-engine-conventions
description: Use when creating or modifying Rails engines, setting up engine namespaces, configuring engine mounting, or working within engine boundaries
---

# Rails Engine Conventions

New domain features are built as isolated Rails engines under `/engines/`. Engines provide namespace isolation, independent migrations, and clean separation from the main app.

## Core Principles

1. **Isolated namespace** — `isolate_namespace` in engine.rb, all classes under engine module
2. **Explicit table names** — Every model sets `self.table_name` with engine prefix
3. **Feature gated** — Engine functionality gated per account
4. **Own the full stack** — Engine contains its own models, controllers, serializers, policies, interactors, queries, workers
5. **Cross-reference carefully** — Use full class paths when referencing main app or other engines

## Engine Structure

```
engines/operations/
├── app/
│   ├── controllers/operations/
│   │   └── api/
│   │       ├── base_controller.rb
│   │       ├── goals_controller.rb
│   │       └── meetings_controller.rb
│   ├── models/operations/
│   │   ├── application_record.rb
│   │   ├── goal.rb
│   │   └── meeting.rb
│   ├── serializers/operations/
│   │   ├── base_serializer.rb
│   │   └── goal_serializer.rb
│   ├── policies/operations/
│   │   └── goal_policy.rb
│   ├── interactors/operations/
│   │   └── goals/
│   │       ├── create_goal.rb
│   │       └── create_goal_organizer.rb
│   ├── queries/operations/
│   │   └── goals_query.rb
│   └── workers/operations/
│       └── sync_goals_worker.rb
├── config/
│   ├── routes.rb
│   └── initializers/
├── db/migrate/
├── lib/operations/
│   └── engine.rb
└── operations.gemspec
```

## Engine Configuration

```ruby
# lib/operations/engine.rb
module Operations
  class Engine < ::Rails::Engine
    isolate_namespace Operations

    initializer 'operations.migration_paths' do |app|
      config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << expanded_path
      end
    end
  end
end
```

## Base Classes

Each engine defines its own abstract base classes that inherit from the main app:

```ruby
# Models
module Operations
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
  end
end

# Controllers
module Operations
  module Api
    class BaseController < ::Ajax::JSONAPI::BaseController
      before_action :verify_operations_enabled!

      private

      def verify_operations_enabled!
        head :not_found unless current_account.operations_engine_enabled?
      end

      def infer_domain_namespace
        Operations
      end
    end
  end
end

# Serializers
module Operations
  class BaseSerializer < ::JSONAPI::BaseSerializer
  end
end

# Policies inherit directly from main app
module Operations
  class GoalPolicy < ::ApplicationPolicy
  end
end
```

## Feature Gating

Every engine controller checks that the feature is enabled for the current account:

```ruby
before_action :verify_operations_enabled!

# The account model has:
# def operations_engine_enabled?
#   feature_toggle_check(:operations_engine)
# end
```

This returns 404 for accounts without the feature — not 403.

## Cross-Namespace References

When referencing main app classes from an engine:

```ruby
# In serializer — reference main app serializer
belongs_to :created_by, serializer: ::JSONAPI::UserSerializer

# In model — reference main app model
belongs_to :account, class_name: '::Account'

# In policy — inherit from main app base
class GoalPolicy < ::ApplicationPolicy
```

When referencing within the same engine, use the engine namespace:

```ruby
has_many :children, serializer: -> { Operations::GoalSerializer }
belongs_to :parent, class_name: 'Operations::Goal'
```

## Migrations

Engine migrations use the engine prefix for table names:

```ruby
class CreateOperationsGoals < ActiveRecord::Migration[7.2]
  def change
    create_table :operations_goals do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :target_date
      t.datetime :archived_at
      t.timestamps
    end
  end
end
```

Migration paths are added via the engine initializer so `rails db:migrate` picks them up.

## Tests

Engine specs live in the main app's spec directory, mirroring the engine namespace:

```
spec/
  requests/operations/api/goals_spec.rb
  models/operations/goal_spec.rb
  policies/operations/goal_policy_spec.rb
  serializers/operations/goal_serializer_spec.rb
  interactors/operations/goals/create_goal_organizer_spec.rb
  queries/operations/goals_query_spec.rb
```

## Quick Reference

| Do | Don't |
|----|-------|
| `isolate_namespace` in engine.rb | Share namespace with main app |
| `self.table_name = 'operations_goals'` | Rely on Rails table name inference |
| Feature gate in base controller | Assume engine is always available |
| `::ClassName` for main app references | Rely on autoload resolution |
| Engine base classes inheriting main app | Direct main app class inheritance |
| Specs in main app's spec directory | Specs inside engine directory |
| Engine prefix on all tables | Unprefixed tables |

## Common Mistakes

1. **Missing table_name** — Engine models MUST explicitly set table names
2. **No feature gate** — Every engine base controller needs the gate
3. **Ambiguous class references** — Always use `::` prefix for main app classes
4. **Migrations without prefix** — Engine tables must be prefixed
5. **Specs in wrong location** — Engine specs live in main app's spec/

**Remember:** Engines are isolated domains. Explicit namespacing, explicit table names, explicit cross-references.
