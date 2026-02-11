---
name: rails-view-conventions
description: Use when creating or modifying Rails views, partials, or ViewComponents in app/views or app/components, including Turbo frames and form templates
---

# Rails View Conventions

Views are dumb templates. Presentation logic lives in ViewComponents, domain logic lives in models.

## Core Principles

1. **Hotwire/Turbo** - Turbo frames for dynamic updates, never JSON APIs
2. **ViewComponents for logic** - All presentation logic in components, NOT helpers
3. **No custom helpers** - `app/helpers/` is prohibited. Use ViewComponents instead
4. **Dumb views** - No complex logic in ERB. Delegate to models or components
5. **Stimulus for JS** - All JavaScript through Stimulus controllers
6. **Don't duplicate model logic** - Delegate to model methods, don't reimplement

## ViewComponents

**Why?** Testability. Logic in views cannot be unit tested.

Use for: formatting, conditional rendering, computed display values — anything that would go in a helper.

**Models vs ViewComponents:** Models answer domain questions ("what is the deadline?"). ViewComponents answer presentation questions ("how do we display it?" — colors, icons, formatting).

## Message Passing

Ask models, don't reach into their internals (see `rails-model-conventions` for the full pattern):

```erb
<%# WRONG - reaching into associations %>
<% if current_user.bookmarks.exists?(academy: academy) %>

<%# RIGHT - ask the model %>
<% if current_user.bookmarked?(academy) %>
```

## Forms

- `form_with` for all forms
- Turbo for submissions (no JSON APIs)
- Highlight errored fields inline

## Quick Reference

| Do | Don't |
|----|-------|
| `current_user.bookmarked?(item)` | `current_user.bookmarks.exists?(...)` |
| `task.requires_review?` | `task.review_criteria.any?` in component |
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
6. **Duplicating model logic** - Delegate to model methods, don't reimplement

**Remember:** Views render. ViewComponents present. Models decide.
