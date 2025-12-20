# Rails Conventions Reviewer Prompt Template

Use this template when dispatching a Rails conventions reviewer subagent.

**Purpose:** Verify implementation follows project's Rails conventions

**Only dispatch for Rails projects, after spec compliance review passes.**

```
Task tool (general-purpose):
  description: "Review Rails conventions for Task N"
  prompt: |
    You are reviewing whether a Rails implementation follows project conventions.

    ## First: Load ALL Convention Skills

    Load these skills and have them ready for reference:
    superpowers:rails-controller-conventions
    superpowers:rails-model-conventions
    superpowers:rails-view-conventions
    superpowers:rails-policy-conventions
    superpowers:rails-job-conventions
    superpowers:rails-migration-conventions
    superpowers:rails-stimulus-conventions
    superpowers:rails-testing-conventions

    ## Files to Review

    [List of files changed in this task]

    ## Your Job

    For each file, check against the corresponding convention skill:

    **Controllers (`app/controllers/`):**
    - Thin controllers? Business logic delegated to models?
    - Message passing OOP? Not reaching into associations?
    - `authorize` called in every action?
    - No JSON/API responses? Using Turbo?

    **Models (`app/models/`):**
    - Clean interfaces? Not leaking implementation?
    - Business logic lives here?
    - Pass objects, not IDs?

    **Views/Components (`app/views/`, `app/components/`):**
    - ViewComponents for any logic? No custom helpers?
    - Turbo frames, not JSON?
    - Message passing in views?

    **Policies (`app/policies/`):**
    - Permission only? No state checks?
    - Using role hierarchy helpers?

    **Jobs (`app/jobs/`):**
    - Idempotent?
    - Thin? Delegating to models?
    - ApplicationJob inheritance?

    **Migrations (`db/migrate/`):**
    - Reversible?
    - Indexes on foreign keys?
    - Handles existing data?

    **Stimulus (`*_controller.js`):**
    - Thin? DOM only?
    - Turbo-first?
    - Cleanup in disconnect?

    **Tests (`spec/`):**
    - No mocking behavior?
    - Explicit factories?
    - Auth tests in policy specs?

    ## Report Format

    - ✅ Conventions followed (if all checks pass)
    - ❌ Convention violations:
      - [file:line] [convention violated] - [what's wrong]
      - [file:line] [convention violated] - [what's wrong]
```
