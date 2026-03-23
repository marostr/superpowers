---
name: jsonapi-conventions
description: Use when creating or modifying JSON:API serializers, rendering responses, handling errors, or working with includes/fieldsets/pagination
---

# JSON:API Conventions

All new API endpoints use JSON:API spec responses via the `jsonapi-serializer` gem and the `Ajax::JSONAPI` concern stack.

## Serializers

### Base Pattern

```ruby
# Engine serializer
module Operations
  class GoalSerializer < Operations::BaseSerializer
    # Operations::BaseSerializer < ::JSONAPI::BaseSerializer
    # ::JSONAPI::BaseSerializer includes JSONAPI::Serializer

    attributes :title,
               :description,
               :company_visible

    attribute :target_date do |goal|
      goal.target_date&.iso8601
    end

    attribute :created_at do |goal|
      goal.created_at.iso8601
    end

    # Relationships
    belongs_to :created_by, serializer: ::JSONAPI::UserSerializer
    has_one :metric
    has_many :observations, serializer: -> { Operations::ObservationSerializer }
    has_many :owners, serializer: -> { Operations::GoalOwnerSerializer }, lazy_load_data: true
    has_many :watchers, lazy_load_data: true

    # Computed meta with viewer-dependent permissions
    meta do |goal, params|
      user = params[:current_user]
      policy = Operations::GoalPolicy.new(user, goal)
      {
        status: goal.current_status,
        can_edit: policy.update?,
        can_delete: policy.destroy?,
        can_transfer_ownership: policy.transfer_ownership?
      }
    end
  end
end
```

### Key Patterns

**Timestamps** — Always format as ISO8601 via attribute blocks:
```ruby
attribute :created_at do |record|
  record.created_at.iso8601
end
```

**Cross-namespace serializers** — Use the full class path or lambdas for circular references:
```ruby
# Main app serializer from engine
belongs_to :user, serializer: ::JSONAPI::UserSerializer

# Circular/self-referential (use lambda)
has_many :children, serializer: -> { Operations::GoalSerializer }
```

**Lazy loading relationships** — Use `lazy_load_data: true` for has_many to avoid N+1:
```ruby
has_many :observations, lazy_load_data: true
```

**Custom IDs** — Some models use UUID instead of numeric ID:
```ruby
set_id :uuid
```

**Computed meta** — Permissions, status, counts calculated at serialization time:
```ruby
meta do |record, params|
  {
    status: record.computed_status,
    permissions: build_permissions(record, params[:current_user])
  }
end
```

## Serializer Hierarchy

```
::JSONAPI::BaseSerializer          # app/serializers/jsonapi/base_serializer.rb
  ├─ ::JSONAPI::UserSerializer     # Main app serializers
  ├─ ::JSONAPI::CurriculumSerializer
  └─ Operations::BaseSerializer    # Engine base
       ├─ Operations::GoalSerializer
       ├─ Operations::MeetingSerializer
       └─ ...
```

The base serializer includes `JSONAPI::Serializer` and provides `as_jsonapi()`.

## Error Handling

Custom error classes live in `Ajax::JSONAPI::Errors::`:

```ruby
# Automatic rescue chains in Ajax::JSONAPI::Concerns::ErrorHandling:
rescue_from ActiveRecord::RecordNotFound -> Ajax::JSONAPI::Errors::RecordNotFound
rescue_from Pundit::NotAuthorizedError   -> Ajax::JSONAPI::Errors::Forbidden
rescue_from ActiveRecord::RecordInvalid  -> Ajax::JSONAPI::Errors::ValidationError
rescue_from StandardError                -> Ajax::JSONAPI::Errors::InternalServerError
```

Error responses follow JSON:API error format:
```json
{
  "errors": [
    {
      "status": "422",
      "code": "validation_error",
      "title": "Validation Error",
      "detail": "Title can't be blank",
      "source": { "pointer": "/data/attributes/title" }
    }
  ]
}
```

In controllers, collect errors from interactor results:
```ruby
if result.success?
  render_jsonapi_response(result.goal, status: :created)
else
  collect_jsonapi_error(result.errors)
  render_jsonapi_response(result.goal || Goal.new)
end
```

## Concern Stack

The `Ajax::JSONAPI::BaseController` assembles these concerns:

| Concern | Purpose |
|---------|---------|
| `DomainInference` | Auto-infer resource, serializer, policy classes from controller name |
| `ErrorHandling` | Rescue chains, JSON:API error responses |
| `Rendering` | `render_jsonapi_response` via serializer |
| `SparseFieldsets` | Filter attributes via `fields[]` param |
| `Filterable` | Apply filters via Pundit policy scope |
| `Sortable` | Sort by `sort` param |
| `Paginatable` | Pagy-based pagination with JSON:API links |
| `IncludesResources` | Eager load via `include` param |
| `UpdateableAttributes` | DSL for PATCH-able fields |
| `LookupBy` | Override default ID lookup |
| `Meta` | Build pagination meta |
| `CustomSpanTracerable` | DataDog tracing |

## Pagination

Uses Pagy with JSON:API links:
```json
{
  "data": [...],
  "meta": { "total_count": 42, "page": 1, "per_page": 25 },
  "links": {
    "self": "/api/goals?page=1",
    "next": "/api/goals?page=2",
    "last": "/api/goals?page=2"
  }
}
```

## Brownfield: Panko Serializers

Legacy controllers use Panko serializers with `render_success`/`render_failure`. These are NOT JSON:API compliant. When modifying legacy endpoints:
- Follow the existing Panko pattern within that controller
- Never mix Panko and JSON:API in the same controller
- For new endpoints, always use JSON:API serializers

## Quick Reference

| Do | Don't |
|----|-------|
| `jsonapi-serializer` for new work | Panko for new endpoints |
| ISO8601 timestamps via attribute blocks | Raw timestamp formats |
| `lazy_load_data: true` for has_many | Eager load all relationships |
| Lambdas for circular serializer refs | String class names |
| `meta` block for permissions/status | Embed permissions in attributes |
| `collect_jsonapi_error` for failures | Manual error JSON |
| `render_jsonapi_response` | `render json:` |
| `set_id :uuid` when model uses UUIDs | Override `id` attribute |

## Common Mistakes

1. **Raw timestamps** — Always use ISO8601 formatting
2. **Missing lazy_load_data** — has_many without it causes N+1
3. **Permissions in attributes** — Use meta block for viewer-dependent data
4. **Mixing serializer types** — One controller = one serializer style
5. **Manual error responses** — Use the error handling concern chain
6. **String serializer references for circular deps** — Use lambdas

**Remember:** JSON:API is the standard. The concern stack handles rendering. Serializers define the shape.
