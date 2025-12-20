---
name: rails-migration-conventions
description: Use when creating or modifying database migrations in db/migrate
---

# Rails Migration Conventions

Conventions for database migrations in this project.

## When to Use This Skill

Automatically activates when working on:
- `db/migrate/**/*.rb`

Use this skill when:
- Creating new migrations
- Modifying existing migrations
- Adding indexes or constraints
- Data migrations

## Core Principles

1. **Always reversible** - Every migration must have working `up` and `down` methods, or use reversible blocks.

2. **Test rollbacks** - Before considering a migration done, verify it rolls back cleanly.

3. **Consider existing data** - Migrations run against production databases with real data. Think about what happens to existing rows.

4. **Index foreign keys** - Every `_id` column gets an index. No exceptions.

5. **Strong types** - Use appropriate column types. Don't store everything as strings.

## Reversibility Patterns

**Preferred - Reversible block:**
```ruby
class AddStatusToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :status, :string, default: 'pending', null: false
    add_index :orders, :status
  end
end
```

**When change isn't enough - Explicit up/down:**
```ruby
class MigrateOrderStatuses < ActiveRecord::Migration[7.1]
  def up
    Order.where(legacy_status: 'complete').update_all(status: 'completed')
  end

  def down
    Order.where(status: 'completed').update_all(legacy_status: 'complete')
  end
end
```

## Data Migration Safety

**WRONG - Assumes clean data:**
```ruby
def up
  add_column :users, :role, :string, null: false  # Fails if table has rows!
end
```

**RIGHT - Handle existing data:**
```ruby
def up
  add_column :users, :role, :string, default: 'member'
  change_column_null :users, :role, false
end
```

**For large tables - Batch updates:**
```ruby
def up
  add_column :orders, :normalized_email, :string

  Order.in_batches(of: 1000) do |batch|
    batch.update_all('normalized_email = LOWER(email)')
  end
end
```

## Indexing Rules

```ruby
# Foreign keys - ALWAYS index
add_reference :comments, :user, foreign_key: true  # Adds index automatically

# Manual foreign keys - add index explicitly
add_column :orders, :customer_id, :bigint
add_index :orders, :customer_id

# Columns in WHERE clauses - index them
add_index :orders, :status
add_index :orders, :created_at

# Composite indexes for multi-column queries
add_index :orders, [:user_id, :status]

# Unique constraints
add_index :users, :email, unique: true
```

## Column Type Guidelines

| Data | Type | Notes |
|------|------|-------|
| Money | `decimal` | Never float! `decimal, precision: 10, scale: 2` |
| Booleans | `boolean` | Not string "true"/"false" |
| Enums | `string` or `integer` | String for readability, integer for performance |
| UUIDs | `uuid` | Enable pgcrypto extension first |
| JSON | `jsonb` | Not `json` - jsonb is indexable |
| Timestamps | `datetime` | Use `timestamps` helper |

## Dangerous Operations

**Removing columns - Two-step deploy:**
```ruby
# Step 1: Ignore column in model (deploy first)
class User < ApplicationRecord
  self.ignored_columns = [:old_column]
end

# Step 2: Remove column (after deploy)
def change
  remove_column :users, :old_column
end
```

**Renaming columns - Copy, not rename:**
```ruby
# WRONG - breaks running app
rename_column :users, :name, :full_name

# RIGHT - additive change
add_column :users, :full_name, :string
# Backfill, deploy, then remove old column later
```

## Quick Reference

| Do | Don't |
|----|-------|
| Reversible migrations | One-way migrations |
| Index all foreign keys | Forget indexes |
| Handle existing data | Assume empty tables |
| Use strong types | Store everything as strings |
| Batch large updates | `update_all` on millions of rows |
| Test rollback | Skip rollback testing |

## Common Mistakes

1. **Not null without default** - Fails on tables with existing rows
2. **Missing indexes** - Slow queries in production
3. **Float for money** - Precision errors
4. **Irreversible migrations** - Can't rollback safely
5. **Large table locks** - Add indexes concurrently for big tables

**Remember:** Migrations run against production. Every change must be safe, reversible, and consider existing data.
