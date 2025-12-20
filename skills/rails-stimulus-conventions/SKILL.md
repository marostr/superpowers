---
name: rails-stimulus-conventions
description: Use when creating or modifying Stimulus controllers in app/components or app/packs/controllers
---

# Rails Stimulus Conventions

Conventions for Stimulus JavaScript controllers in this project.

## When to Use This Skill

Automatically activates when working on:
- `app/components/**/*_controller.js`
- `app/packs/controllers/*_controller.js`

Use this skill when:
- Creating new Stimulus controllers
- Adding interactivity to ViewComponents
- Modifying existing controller behavior

## Core Principles

1. **Thin Controllers**: Controllers handle DOM interaction ONLY. No business logic, no data transformation, no complex calculations.

2. **Turbo-First**: If it can be done server-side with Turbo Streams/Frames, don't do it in JS. Controllers enhance, not replace.

3. **Consistent Structure**:
   - `static targets` and `static values` declared at top
   - `connect()` for setup, `disconnect()` for cleanup (always clean up!)
   - Event handlers named `handle*` (e.g., `handleClick`, `handleSubmit`)
   - Private methods use `#` prefix (ES private fields)

4. **No Inline HTML/SVG**: Extract markup to templates or pass via data attributes.

5. **Naming Conventions**:
   - Standalone: `{feature}_controller.js` in `app/packs/controllers/`
   - ViewComponent: `component_controller.js` colocated with component

## Controller Structure Template

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output", "input"]
  static values = {
    url: String,
    delay: { type: Number, default: 300 }
  }

  connect() {
    // Setup - add listeners, initialize state
  }

  disconnect() {
    // Cleanup - remove listeners, clear timers
  }

  // Public action methods (called from data-action)
  handleClick(event) {
    event.preventDefault()
    this.#doSomething()
  }

  // Private methods
  #doSomething() {
    // Implementation
  }
}
```

## Quick Reference

| Do | Don't |
|----|-------|
| DOM manipulation only | Business logic in JS |
| Turbo Streams for updates | Fetch + manual DOM updates |
| `static targets` / `static values` | Query selectors everywhere |
| `disconnect()` cleanup | Memory leaks from listeners |
| `handle*` for event methods | Inconsistent naming |
| Data attributes for config | Hardcoded values |
| Small, focused controllers | Mega-controllers |

## Turbo-First Examples

**WRONG** - Fetching and rendering in JS:
```javascript
async loadContent() {
  const response = await fetch(this.urlValue)
  const html = await response.text()
  this.outputTarget.innerHTML = html
}
```

**RIGHT** - Let Turbo handle it:
```erb
<%= turbo_frame_tag "content", src: content_path, loading: :lazy %>
```

Or trigger a Turbo visit:
```javascript
handleClick() {
  Turbo.visit(this.urlValue)
}
```

## Advanced Patterns

### Outlets - Controller Communication

Connect controllers to reference each other:

```javascript
// parent_controller.js
export default class extends Controller {
  static outlets = ["child"]

  notify() {
    this.childOutlets.forEach(child => child.refresh())
  }
}

// In HTML
<div data-controller="parent" data-parent-child-outlet=".child-component">
  <div class="child-component" data-controller="child">...</div>
</div>
```

### Custom Events - Decoupled Communication

Dispatch events for loose coupling between controllers:

```javascript
// sender_controller.js
handleComplete() {
  this.dispatch("completed", { detail: { id: this.idValue } })
}

// In HTML - receiver listens
<div data-controller="sender receiver"
     data-action="sender:completed->receiver#handleNotification">
```

### Debounce - Rate Limiting

For search inputs, resize handlers, etc:

```javascript
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.#performSearch()
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)  // Always cleanup!
  }
}
```

### Lazy Loading with IntersectionObserver

Load content when element enters viewport:

```javascript
export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver(
      entries => this.#handleIntersection(entries),
      { threshold: 0.1 }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  #handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.#loadContent()
        this.observer.unobserve(this.element)
      }
    })
  }

  #loadContent() {
    // Trigger Turbo frame load or similar
    this.element.src = this.element.dataset.lazySrc
  }
}
```

## Common Mistakes

1. **Fat controllers** - Move logic to server, use Turbo
2. **Missing cleanup** - Always implement `disconnect()` if `connect()` adds listeners
3. **Inline HTML strings** - Use templates or server rendering
4. **Direct fetch calls** - Prefer Turbo Frames/Streams
5. **Querying outside element** - Use targets, stay within controller scope
6. **Forgetting values have defaults** - Declare defaults in static values
7. **Not cleaning up observers** - IntersectionObserver, MutationObserver need disconnect
8. **Missing timeout cleanup** - Clear debounce timers in disconnect

**Remember:** The best Stimulus controller is the one you don't have to write because Turbo handles it.
