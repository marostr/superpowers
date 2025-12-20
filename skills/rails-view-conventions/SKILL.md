---
name: rails-view-conventions
description: Use when creating or modifying Rails views, partials, or ViewComponents in app/views or app/components
---

# Rails View Conventions

Conventions for Rails views and ViewComponents in this project.

## When to Use This Skill

Automatically activates when working on:
- `app/views/**/*.erb`
- `app/components/**/*.rb`
- `app/helpers/**/*.rb`

Use this skill when:
- Creating new views or partials
- Creating or modifying ViewComponents
- Touching helper files (to migrate them to ViewComponents)
- Adding Turbo frames or streams
- Implementing Stimulus controllers
- Working on dynamic UI updates

## Core Responsibilities

1. **View Templates**: Create and maintain ERB templates, layouts, and partials
2. **Asset Management**: Handle CSS, JavaScript, and image assets
3. **ViewComponents**: All presentation logic goes in components, NOT helpers
4. **Frontend Architecture**: Organize views following Rails conventions
5. **Responsive Design**: Ensure views work across devices

## Core Principles

1. **Hotwire/Turbo**: Use Turbo frames for dynamic updates - never JSON APIs
2. **Stimulus for JS**: All JavaScript behavior through Stimulus controllers
3. **Minimal JS**: Keep JavaScript logic to absolute minimum
4. **Dumb Views**: No complex logic in views - delegate to models or components
5. **Partials**: Extract reusable components into partials
6. **ViewComponents**: Use for any presentation logic - components over partials when logic needed
7. **NO CUSTOM HELPERS**: Custom helpers (`app/helpers/`) are prohibited - use ViewComponents instead. Rails built-in helpers (`form_with`, `image_tag`, etc.) are fine.
8. **NEVER use API/JSON calls** - use Turbo frames and streams instead

## View Best Practices

- Use partials for simple reusable markup (no logic)
- Use ViewComponents when any logic is needed
- Keep logic minimal in views
- Use semantic HTML5 elements
- Follow Rails naming conventions

## ViewComponents (Required for Presentation Logic)

**Why ViewComponents over inline logic?** Testability. Logic in views cannot be unit tested. Logic in ViewComponents can be tested in isolation.

Use ViewComponents for:
- Any formatting or display logic
- Conditional rendering
- Computed values for display
- Anything that would traditionally go in a helper

**Never inline logic in views** - even "simple" logic belongs in a ViewComponent where it can be tested.

ViewComponents are testable, encapsulated, and keep views clean.

## Business Logic vs View Logic

Models answer domain questions. ViewComponents answer presentation questions. Deriving display states from domain data is view logic - choosing colors, formatting messages, selecting icons, mapping values to display variants. This belongs in ViewComponents, not models.

## Asset Pipeline

### Stylesheets
- Organize CSS/SCSS files logically
- Use asset helpers for images
- Implement responsive design
- Follow BEM or similar methodology

### JavaScript
- Use Stimulus for interactivity
- Keep JavaScript unobtrusive
- Use data attributes for configuration

## Forms

- Use `form_with` for all forms
- Implement proper CSRF protection
- Add client-side validations
- Use Rails form helpers
- Use Turbo for form submissions (no JSON APIs)
- Error handling: highlight errored fields inline, or show errors in flash if field highlighting not possible

## Message Passing in Views (Critical)

**WRONG** - Reaching into model internals:
```erb
<% if current_user.bookmarks.exists?(academy: academy) %>
<%= academy.enrollments.where(status: :active).count %>
```

**RIGHT** - Ask the model:
```erb
<% if current_user.bookmarked?(academy) %>
<%= academy.active_enrollment_count %>
```

## Hotwire Integration

- Implement Turbo frames for partial page updates
- Use Turbo streams for real-time updates
- Create focused Stimulus controllers
- Keep interactions smooth

```erb
<%= turbo_frame_tag "academy_#{academy.id}" do %>
  <!-- Content that updates dynamically -->
<% end %>
```

## Quick Reference

| Do | Don't |
|----|-------|
| `current_user.bookmarked?(item)` | `current_user.bookmarks.exists?(...)` |
| Turbo frames for updates | JSON API calls |
| Stimulus for JS behavior | Inline JavaScript |
| Partials for simple markup | Duplicated markup |
| ViewComponents for logic | Custom helpers (`app/helpers/`) |
| Semantic HTML5 | Divs for everything |

## Common Mistakes

1. **Logic in views** - Move to ViewComponents (testable) not inline in views (untestable)
2. **Creating custom helpers** - `app/helpers/` is prohibited, use ViewComponents instead
3. **Inlining "simple" logic** - Even simple ternaries belong in ViewComponents for testability
4. **Reaching into associations** - Use model methods instead
5. **Inline JavaScript** - Use Stimulus controllers
6. **JSON API calls** - Use Turbo frames/streams
7. **Duplicated markup** - Extract to partials or ViewComponents

**Remember:** Views should be clean, semantic, and focused on presentation. Business logic belongs in models, presentation logic in ViewComponents.
