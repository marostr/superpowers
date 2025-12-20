---
name: rails-stimulus-conventions
description: Use when creating or modifying Stimulus controllers in app/components or app/packs/controllers
---

# Rails Stimulus Conventions

Conventions for Stimulus JavaScript controllers in this project.

## Core Principles

1. **Thin Controllers** - DOM interaction ONLY. No business logic or data transformation
2. **Turbo-First** - If it can be done server-side with Turbo, don't do it in JS
3. **Always cleanup** - `disconnect()` must clean up what `connect()` creates
4. **No inline HTML** - Extract markup to templates or data attributes

## Structure

- `static targets` and `static values` at top
- `connect()` for setup, `disconnect()` for cleanup
- Event handlers named `handle*` (e.g., `handleClick`)
- Private methods use `#` prefix

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { url: String }

  connect() { /* setup */ }
  disconnect() { /* cleanup timers, observers, listeners */ }

  handleClick(event) {
    event.preventDefault()
    Turbo.visit(this.urlValue)  // Prefer Turbo over fetch
  }
}
```

## Turbo-First Pattern

```javascript
// WRONG - manual fetch
async load() {
  const html = await fetch(this.urlValue).then(r => r.text())
  this.outputTarget.innerHTML = html
}

// RIGHT - let Turbo handle it
handleClick() { Turbo.visit(this.urlValue) }
```

Or use lazy Turbo frames: `<%= turbo_frame_tag "content", src: path, loading: :lazy %>`

## Quick Reference

| Do | Don't |
|----|-------|
| DOM manipulation only | Business logic in JS |
| Turbo for updates | Fetch + manual DOM |
| `static targets/values` | Query selectors |
| `disconnect()` cleanup | Memory leaks |
| `handle*` naming | Inconsistent names |

## Common Mistakes

1. **Fat controllers** - Move logic to server, use Turbo
2. **Missing cleanup** - Clear timers, disconnect observers in `disconnect()`
3. **Direct fetch** - Prefer Turbo Frames/Streams
4. **Querying outside element** - Use targets, stay within scope

**Remember:** The best Stimulus controller is one you don't write because Turbo handles it.
