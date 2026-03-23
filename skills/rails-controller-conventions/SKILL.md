---
name: rails-controller-conventions
description: Use when creating or modifying Rails controllers, adding actions, configuring routes, or handling JSON:API responses
---

# Rails Controller Conventions

Controllers are thin JSON:API request handlers. They authorize, delegate to interactors, and render via the JSONAPI concern stack — nothing more.

## Controller Hierarchy

All new controllers MUST inherit from the JSON:API base:

```ruby
# Standard new controller
class Ajax::JSONAPI::WidgetsController < Ajax::JSONAPI::BaseController
end

# Engine controller
class Operations::Api::GoalsController < Operations::Api::BaseController
  # Operations::Api::BaseController < Ajax::JSONAPI::BaseController
  # Adds: verify_operations_enabled!, domain namespace inference
end
```

**Never** create new controllers inheriting `Ajax::AccountController` (legacy) or `Api::BaseController` (external API).

## Brownfield Reality

The codebase has ~68 legacy `Ajax::AccountController` controllers using `render_success`/`render_failure` with Panko serializers. When modifying these:
- Follow the existing patterns within that controller
- Don't refactor to JSON:API unless explicitly asked
- Never mix patterns — a controller is either JSON:API or legacy, not both

## JSON:API Concern Stack DSL

The `Ajax::JSONAPI::BaseController` provides these DSLs via concerns:

```ruby
class Ajax::JSONAPI::GoalsController < Ajax::JSONAPI::BaseController
  # Override primary key lookup (default: :id)
  lookup_by :uuid

  # Declare PATCH-able attributes
  updateable_attributes :title,
                        :description,
                        :target_date,
                        :company_visible

  # Whitelist includable relationships
  def permitted_includes
    %w[metric observations watchers owners created_by]
  end

  # Allowed sort columns
  def sortable_fields
    %w[title target_date created_at]
  end

  # Custom filtering logic
  def apply_custom_filters(resources)
    Operations::GoalsQuery.call(
      resources,
      user: current_user,
      filters: consume_custom_filters
    )
  end

  # Eager loading hook
  def prepare_resources(resources, options = {})
    resources.includes(:metric, :owners, :watchers)
  end
end
```

## Default Actions

`Ajax::JSONAPI::BaseController` provides default `index`, `show`, and `update` actions with authorization. `create` and `destroy` raise `NotImplementedError` — you must implement them explicitly:

```ruby
def create
  result = CreateGoalOrganizer.perform(
    params: jsonapi_params,
    account: current_account,
    user: current_user
  )

  if result.success?
    render_jsonapi_response(result.goal, status: :created)
  else
    collect_jsonapi_error(result.errors)
    render_jsonapi_response(result.goal || Goal.new)
  end
end
```

## Authorization

Every action uses Pundit. The base controller handles `index` (via `policy_scope`) and `show`/`update` (via `authorize`). For custom actions:

```ruby
def create
  authorize Goal  # Class-level for creation
  # ...
end

def destroy
  @resource = find_resource
  authorize @resource  # Instance-level for destruction
  # ...
end
```

## Parameter Extraction

JSON:API params come nested under `data.attributes`:

```ruby
# Extracted via base controller
jsonapi_params  # => params.require(:data).require(:attributes)
```

## Engine Feature Gates

Engine controllers add a feature gate:

```ruby
class Operations::Api::BaseController < Ajax::JSONAPI::BaseController
  before_action :verify_operations_enabled!

  private

  def verify_operations_enabled!
    head :not_found unless current_account.operations_engine_enabled?
  end
end
```

## DataDog Tracing

Engine controllers use squad-attributed tracing:

```ruby
class Operations::Api::GoalsController < Operations::Api::BaseController
  prepend_before_action :operations_trace
end
```

## Quick Reference

| Do | Don't |
|----|-------|
| Inherit `Ajax::JSONAPI::BaseController` | Create new `Ajax::AccountController` subclasses |
| `updateable_attributes` DSL | Manual strong params for PATCH |
| `apply_custom_filters` with Query objects | Inline filtering logic |
| Delegate to interactors/organizers | Business logic in controllers |
| `authorize` / `policy_scope` in every action | Skip authorization |
| `render_jsonapi_response` | `render json:` manually |
| `jsonapi_params` for attribute extraction | `params.require(:resource)` |
| `lookup_by :uuid` when needed | Override `find_resource` manually |

## Common Mistakes

1. **New controller inheriting Ajax::AccountController** — Always use JSON:API base for new work
2. **Business logic in create/update** — Delegate to interactors
3. **Missing authorization** — Every action must authorize
4. **Mixing patterns** — Don't add JSON:API rendering to a legacy controller or vice versa
5. **Manual JSON rendering** — Use the concern stack's `render_jsonapi_response`
6. **Fat prepare_resources** — Keep eager loading focused, use Query objects for filtering

**Remember:** Controllers authorize and delegate. Interactors do the work. The concern stack handles rendering.
