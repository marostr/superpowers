---
name: rails-migration-conventions
description: Use when creating or modifying database migrations, adding columns, creating indexes, handling data backfills, or performing schema changes
---

# Rails Migration Conventions

Migrations run against production with real data. Every migration must be safe, reversible, and data-aware.

## Core Principles

1. **Always reversible** — Every migration must roll back cleanly
2. **Test rollbacks** — Verify before considering done
3. **Consider existing data** — Tables have real rows in production
4. **Index foreign keys** — Every `_id` column gets an index. No exceptions
5. **Strong types** — Use appropriate column types, not strings for everything

## Engine Migrations

Engine migrations live in `engines/engine_name/db/migrate/` and are automatically picked up via the engine initializer. Table names MUST use the engine prefix:

```ruby
# engines/operations/db/migrate/20240101000000_create_operations_goals.rb
class CreateOperationsGoals < ActiveRecord::Migration[7.2]
  def change
    create_table :operations_goals do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :target_date
      t.boolean :company_visible, default: false, null: false
      t.datetime :archived_at
      t.timestamps
    end

    add_index :operations_goals, [:account_id, :archived_at]
  end
end
```

## Data Safety

```ruby
# WRONG - fails if table has rows
add_column :users, :role, :string, null: false

# RIGHT - handle existing data
add_column :users, :role, :string, default: 'member'
change_column_null :users, :role, false
```

For large tables, batch updates: `Model.in_batches(of: 1000) { |b| b.update_all(...) }`

## Indexing

```ruby
add_reference :comments, :user, foreign_key: true  # Auto-indexes
add_column :orders, :customer_id, :bigint
add_index :orders, :customer_id  # Manual FKs need explicit index
add_index :orders, [:user_id, :status]  # Composite for multi-column queries
```

## Column Types

| Data | Type | Notes |
|------|------|-------|
| Money | `decimal` | Never float! `precision: 10, scale: 2` |
| JSON | `jsonb` | Not `json` — jsonb is indexable |
| Booleans | `boolean` | Not string "true"/"false" |
| Soft delete | `datetime` | `archived_at` for engines, `deleted_at` for paranoia |

## Dangerous Operations

- **Remove column** — First `self.ignored_columns = [:col]`, deploy, then remove
- **Rename column** — Add new, backfill, deploy, remove old. Never `rename_column`
- **Large table indexes** — Add concurrently

## Quick Reference

| Do | Don't |
|----|-------|
| Engine prefix on table names | Unprefixed engine tables |
| Reversible migrations | One-way migrations |
| Index all foreign keys | Forget indexes |
| Handle existing data | Assume empty tables |
| Test rollback | Skip rollback testing |
| Batch large updates | `update_all` on millions |

## Common Mistakes

1. **Missing engine prefix** — Engine tables MUST be prefixed (e.g., `operations_goals`)
2. **Not null without default** — Fails on existing rows
3. **Missing indexes** — Slow queries in production
4. **Float for money** — Precision errors
5. **Irreversible migrations** — Can't rollback safely

**Remember:** Migrations run against production. Safe, reversible, data-aware. Engine tables are prefixed.
