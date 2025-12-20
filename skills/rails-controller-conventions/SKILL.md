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
4. **No Exception Control Flow**: Never catch exceptions for control flow - let them propagate
5. **NEVER use raw SQL strings** - use ActiveRecord query methods or Arel instead

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
| `user.bookmarked?(academy)` | `user.bookmarks.exists?(...)` |
| `academy.bookmark_count` | `academy.bookmarks.count` |
| Model methods for state | Inline association queries |
| Turbo Streams | JSON responses |
| 7 RESTful actions | Custom action proliferation |
| `before_action` for setup | Repeated code in actions |

## Common Mistakes

1. **Missing authorize calls** - Every action MUST call `authorize`
2. **Checking state in views** - Move to model method
3. **Business logic in controller** - Move to model
4. **respond_to with json** - Use turbo_stream only
5. **Catching exceptions for control flow** - Let exceptions propagate
6. **Fat actions** - Extract to model methods
