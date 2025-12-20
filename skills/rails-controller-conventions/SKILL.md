---
name: rails-controller-conventions
description: Use when creating or modifying Rails controllers in app/controllers
---

# Rails Controller Conventions

Conventions for Rails controllers in this project.

## When to Use This Skill

Automatically activates when working on:
- `app/controllers/**/*.rb`

Use this skill when:
- Creating new controllers
- Adding or modifying controller actions
- Implementing request/response handling
- Setting up authentication or authorization
- Configuring routes
- Working with Turbo/Hotwire responses

## Core Responsibilities

1. **Thin Controllers**: No business logic - delegate to models
2. **Request Handling**: Process parameters, handle formats, manage responses
3. **Authorization**: Every action MUST call `authorize` - no exceptions
4. **Routing**: Design clean, RESTful routes

## Core Principles

1. **Message Passing OOP**: Ask objects, don't reach into their internals
2. **Hotwire/Turbo**: Never write API/JSON code
3. **RESTful**: Stick to 7 standard actions, one controller per resource
4. **CRUD Resources for State**: Model state changes as singular resources, not custom actions
5. **No Exception Control Flow**: Never catch exceptions for control flow - let them propagate
6. **NEVER use raw SQL strings** - use ActiveRecord query methods or Arel instead

## CRUD Resources for State Changes (Critical)

When an action doesn't map to standard CRUD, introduce a new resource rather than custom actions.

**WRONG** - Custom actions:
```ruby
resources :cards do
  post :close
  post :reopen
  post :pin
  post :unpin
end
```

**RIGHT** - Singular resources for state:
```ruby
resources :cards do
  resource :closure    # POST = close, DELETE = reopen
  resource :pin        # POST = pin, DELETE = unpin
  resource :goldness   # POST = gild, DELETE = ungild
end
```

**Pattern**: `create` enables the state, `destroy` disables it. The controller is thin - it delegates to model methods:

```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close
    respond_to { |format| format.turbo_stream { render_card_replacement } }
  end

  def destroy
    @card.reopen
    respond_to { |format| format.turbo_stream { render_card_replacement } }
  end
end
```

## Scoping Concerns

Bundle `before_action` setup with related helper methods in concerns:

```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        [@card, :card_container],
        partial: "cards/container",
        method: :morph
      )
    end
end
```

Controllers include the concern and get both setup and helpers:
```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped  # Provides @card, @board, render_card_replacement
end
```

## Message Passing (Critical)

**WRONG** - Reaching into associations:
```ruby
# In view - asking about internals
current_user.academy_bookmarks.exists?(academy: academy)

# In controller - manipulating internals
@bookmark = current_user.academy_bookmarks.find_by(academy: @academy)
```

**RIGHT** - Ask the object:
```ruby
# In view - ask user
current_user.bookmarked?(academy)

# Or ask academy
academy.bookmarked_by?(current_user)

# Model provides the answer
class User < ApplicationRecord
  def bookmarked?(academy)
    academy_bookmarks.exists?(academy: academy)
  end
end
```

**Principle**: Sender sends message to Receiver. Receiver performs action or returns data. Sender never reaches into Receiver's internal structure.

## Authorization (Critical)

Every controller action MUST call `authorize`. This ensures Pundit policies are enforced.

**Key points:**
- Use `[:companies, resource]` for namespaced policies
- For `index`/`new`: authorize the class (no instance yet)
- For actions with instances: authorize the instance
- Authorize BEFORE performing the action

## Quick Reference

| Do | Don't |
|----|-------|
| `resource :closure` | `post :close, :reopen` |
| `user.bookmarked?(academy)` | `user.bookmarks.exists?(...)` |
| Model methods for state | Inline association queries |
| Scoping concerns | Repeated `before_action` setup |
| Turbo Streams | JSON responses |
| 7 RESTful actions | Custom action proliferation |

## Common Mistakes

1. **Custom actions for state** - Use singular resources (`resource :closure` not `post :close`)
2. **Missing authorize calls** - Every action MUST call `authorize`
3. **Repeated before_action setup** - Extract to scoping concerns
4. **Business logic in controller** - Move to model
5. **respond_to with json** - Use turbo_stream only
6. **Fat actions** - Extract to model methods
