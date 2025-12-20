---
name: rails-model-conventions
description: Use when creating or modifying Rails models in app/models
---

# Rails Model Conventions

Conventions for Rails models in this project.

## When to Use This Skill

Automatically activates when working on:
- `app/models/**/*.rb`

Use this skill when:
- Creating new models
- Adding validations, associations, or scopes
- Implementing business logic
- Optimizing queries
- Working with callbacks
- Designing clean interfaces for model methods

## Core Responsibilities

1. **Model Design**: Create well-structured ActiveRecord models with appropriate validations
2. **Associations**: Define relationships between models (has_many, belongs_to, has_and_belongs_to_many, etc.)
3. **Business Logic**: Models own ALL domain logic - this is where it belongs, not controllers
4. **Query Optimization**: Implement efficient scopes and query methods
5. **Database Design**: Ensure proper normalization and indexing

## Clean Interfaces (Critical)

A **clean interface** doesn't leak implementation details. It's easy to understand, doesn't expose private parts, and doesn't create excessive coupling.

**WRONG** - Leaking implementation:
```ruby
# Controller/view reaching into model internals
user.bookmarks.where(academy: academy).exists?
user.bookmarks.create!(academy: academy)
academy.enrollments.where(status: :active).count
```

**RIGHT** - Clean interface:
```ruby
# Model exposes intent-based methods
class User < ApplicationRecord
  def bookmarked?(academy)
    academy_bookmarks.exists?(academy: academy)
  end

  def bookmark(academy)
    academy_bookmarks.find_or_create_by(academy: academy)
  end

  def unbookmark(academy)
    academy_bookmarks.where(academy: academy).destroy_all
  end
end

class Academy < ApplicationRecord
  def active_enrollment_count
    enrollments.active.count
  end
end
```

**Principle**: Sender sends message to Receiver. Receiver performs action or returns data. Sender never reaches into Receiver's internal structure.

### Pass Objects, Not Primitives

Model methods should accept domain objects, not primitive IDs. This avoids primitive obsession - the caller already has the object loaded, the method signature is self-documenting, and you can't accidentally pass the wrong ID.

## Model Organization

Order: constants → associations → validations → scopes → callbacks → public methods → private methods

## Validations

- Use built-in validators when possible
- Create custom validators for complex business rules
- Consider database-level constraints for critical validations
- Validate at model level, not controller

## Associations

- Use appropriate association types
- Consider `:dependent` options carefully
- Implement counter caches where beneficial
- Use `:inverse_of` for bidirectional associations

## Scopes and Queries

- Create named scopes for reusable queries
- Avoid N+1 queries with `includes`/`preload`/`eager_load`
- Use database indexes for frequently queried columns
- Consider using Arel for complex queries
- **NEVER use raw SQL strings** - use ActiveRecord query methods or Arel instead

## Callbacks

- Use callbacks **sparingly**
- Prefer logic inside model methods with explicit calling
- Keep callbacks focused on model's core concerns
- Never use callbacks for external side effects (emails, APIs)

## Performance Considerations

- Index foreign keys and columns used in WHERE clauses
- Use counter caches for association counts
- Implement efficient bulk operations
- Monitor slow queries

## Quick Reference

| Do | Don't |
|----|-------|
| `user.bookmark(academy)` | `user.bookmarks.create(...)` |
| `academy.enrolled?(student)` | `academy.enrollments.exists?(...)` |
| `academy.active_enrollment_count` | `academy.enrollments.active.count` |
| Scopes for queries | Query logic in controllers |
| Intent-based method names | Exposing associations directly |
| `:inverse_of` on associations | Bidirectional without inverse |
| Counter cache | `.count` on associations |

## Common Mistakes

1. **Anemic models** - Put business logic in models, not controllers
2. **Leaking implementation** - Provide clean interface methods instead
3. **Callback hell** - Use callbacks sparingly, prefer explicit calls
4. **Missing validations** - Validate at model level
5. **N+1 queries** - Use counter_cache, includes, eager loading
6. **Missing indexes** - Index foreign keys and query columns
7. **View logic in models** - Display formatting, CSS classes, icons, and user-facing messages belong in ViewComponents, not models. Models answer domain questions ("what is the deadline?"), ViewComponents answer presentation questions ("how do we display it?")
