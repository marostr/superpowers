---
name: rails-view-conventions
description: Use when creating or modifying Rails views, partials, or ViewComponents in app/views or app/components
---

# Rails View Conventions

Conventions for Rails views and ViewComponents in this project.

## Core Principles

1. **Hotwire/Turbo** - Use Turbo frames for dynamic updates, never JSON APIs
2. **ViewComponents for logic** - All presentation logic in components, NOT helpers
3. **NO custom helpers** - `app/helpers/` is prohibited. Use ViewComponents instead
4. **Dumb views** - No complex logic in ERB, delegate to models or components
5. **Stimulus for JS** - All JavaScript through Stimulus controllers

## ViewComponents (Required for Presentation Logic)

**Why?** Testability. Logic in views cannot be unit tested.

Use ViewComponents for: formatting, conditional rendering, computed display values, anything that would go in a helper.

**Models vs ViewComponents:** Models answer domain questions ("what is the deadline?"). ViewComponents answer presentation questions ("how do we display it?" - colors, icons, formatting).

## Message Passing (Critical)

```erb
<%# WRONG - reaching into associations %>
<% if current_user.bookmarks.exists?(academy: academy) %>

<%# RIGHT - ask the model %>
<% if current_user.bookmarked?(academy) %>
```

## Forms

- Use `form_with` for all forms
- Use Turbo for submissions (no JSON APIs)
- Highlight errored fields inline

## Quick Reference

| Do | Don't |
|----|-------|
| `current_user.bookmarked?(item)` | `current_user.bookmarks.exists?(...)` |
| Turbo frames for updates | JSON API calls |
| Stimulus for JS behavior | Inline JavaScript |
| Partials for simple markup | Duplicated markup |
| ViewComponents for logic | Custom helpers |

## Common Mistakes

1. **Logic in views** - Move to ViewComponents for testability
2. **Creating custom helpers** - Use ViewComponents instead
3. **Reaching into associations** - Use model methods
4. **Inline JavaScript** - Use Stimulus controllers
5. **JSON API calls** - Use Turbo frames/streams
