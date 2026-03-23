---
name: query-object-conventions
description: Use when creating or modifying query objects for complex filtering, sorting, or data shaping logic
---

# Query Object Conventions

Complex filtering and data shaping logic lives in query objects, not controllers or models. Query objects use `Patterns::Query` from the `rails-patterns` gem.

## Core Principles

1. **One query class per use case** — Each query object serves a specific filtering/shaping need
2. **Composable with `.then`** — Chain filter methods using Ruby's `.then` for readability
3. **Integrate with controllers** — Called from `apply_custom_filters` in JSON:API controllers
4. **Return relations** — Always return ActiveRecord relations, not arrays

## Basic Pattern

```ruby
class Operations::GoalsQuery < Patterns::Query
  queries Operations::Goal

  private

  def query
    relation
      .then { |r| filter_by_view(r) }
      .then { |r| filter_by_active(r) }
      .then { |r| filter_by_owner(r) }
  end

  def filter_by_view(relation)
    case params[:view]
    when 'my_goals'
      relation.by_owner_ids([user.id])
    when 'people_i_manage'
      relation.by_owner_ids(user.child_ids)
    when 'company'
      relation.company_visible
    else
      relation
    end
  end

  def filter_by_active(relation)
    return relation if params[:include_archived]
    relation.active
  end

  def filter_by_owner(relation)
    return relation unless params[:owner_id]
    relation.by_owner_ids([params[:owner_id]])
  end
end
```

## Calling from Controllers

Query objects integrate with the JSON:API controller's `apply_custom_filters` hook:

```ruby
class Operations::Api::GoalsController < Operations::Api::BaseController
  def apply_custom_filters(resources)
    Operations::GoalsQuery.call(
      resources,
      user: current_user,
      filters: consume_custom_filters
    )
  end
end
```

`consume_custom_filters` extracts filter params from the JSON:API request and marks them as consumed so they don't trigger unknown-filter errors.

## Constructor Pattern

Query objects receive the base relation and named parameters:

```ruby
# Patterns::Query provides:
# - `relation` — the base ActiveRecord relation passed in
# - `params` — the hash of named parameters
# - `query` — override this to build your filtered relation

Operations::GoalsQuery.call(
  policy_scope(Operations::Goal),  # base relation (already scoped by Pundit)
  user: current_user,              # available as `params[:user]` or define accessor
  filters: { view: 'my_goals' }   # available as `params[:filters]`
)
```

## Directory Structure

```
app/queries/
  operations/
    goals_query.rb
    meetings_query.rb
    update_request_assignments_query.rb
    discussion_topics_query.rb
    action_items_query.rb
```

## Quick Reference

| Do | Don't |
|----|-------|
| `Patterns::Query` base class | Raw scopes in controllers |
| `.then` chains for readability | Nested conditionals |
| Return ActiveRecord relations | Return arrays |
| One query per use case | God query with 20 filters |
| Call from `apply_custom_filters` | Call from model scopes |
| Accept base relation as input | Hard-code the base scope |

## Common Mistakes

1. **Filtering in controllers** — Extract to query objects
2. **Returning arrays** — Must return relations for pagination/sorting to work
3. **Hard-coded base scope** — Accept the relation as input; let Pundit scope it first
4. **Missing filter methods** — Each filter should be its own method for clarity

**Remember:** Query objects filter. Models scope. Controllers delegate.
