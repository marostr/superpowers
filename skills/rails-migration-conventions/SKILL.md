---
name: rails-migration-conventions
description: Use when creating or modifying database migrations, adding columns, creating indexes, handling data backfills, or performing schema changes
---

# Rails Migration Conventions

Migrations run against production with real data. Every migration must be safe, reversible, and data-aware.

## Core Principles

1. **Always reversible** - Every migration must roll back cleanly
2. **Test rollbacks** - Verify before considering done
3. **Consider existing data** - Tables have real rows in production
4. **Index foreign keys** - Every `_id` column gets an index. No exceptions
5. **Strong types** - Use appropriate column types, not strings for everything

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

## Dangerous Operations

- **Remove column** - First `self.ignored_columns = [:col]`, deploy, then remove
- **Rename column** - Add new, backfill, deploy, remove old. Never `rename_column`
- **Large table indexes** - Add concurrently

## Quick Reference

| Do | Don't |
|----|-------|
| Reversible migrations | One-way migrations |
| Index all foreign keys | Forget indexes |
| Handle existing data | Assume empty tables |
| Test rollback | Skip rollback testing |
| Batch large updates | `update_all` on millions |

## Common Mistakes

1. **Not null without default** - Fails on existing rows
2. **Missing indexes** - Slow queries in production
3. **Float for money** - Precision errors
4. **Irreversible migrations** - Can't rollback safely

**Remember:** Migrations run against production. Safe, reversible, data-aware.
