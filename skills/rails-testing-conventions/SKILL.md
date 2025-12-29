---
name: rails-testing-conventions
description: Use when creating or modifying RSpec tests in spec/
---

# Rails Testing Conventions

Conventions for RSpec tests in this project.

## Core Principles (Non-Negotiable)

1. **Never test mocked behavior** - If you mock it, you're not testing it
2. **No mocks in integration tests** - Request/system specs use real data. WebMock for external APIs only
3. **Pristine test output** - Capture and verify expected errors, don't let them pollute output
4. **All failures are your responsibility** - Even pre-existing. Never ignore failing tests
5. **Coverage cannot decrease** - Never delete a failing test, fix the root cause

## Spec Types

| Type | Location | Use For |
|------|----------|---------|
| Request | `spec/requests/` | Single action (CRUD, redirects). Never test auth here |
| System | `spec/system/` | Multi-step flows. Use `have_text`, never `sleep` |
| Model | `spec/models/` | Public interface + Shoulda matchers |
| Policy | `spec/policies/` | ALL authorization tests belong here |
| Component | `spec/components/` | ViewComponent rendering |

## Factory Rules

- **Explicit attributes** - `create(:company_user, role: :mentor)` not `create(:user)`
- **Use traits** - `:published`, `:draft` for variations
- **`let` by default** - `let!` only when record must exist before test
- **Create in final state** - No `update!` in before blocks

## Quick Reference

| Do | Don't |
|----|-------|
| Test real behavior | Test mocked behavior |
| WebMock for external APIs | Mock internal classes |
| Explicit factory attributes | Rely on factory defaults |
| `let` by default | `let!` everywhere |
| Capture expected errors | Let errors pollute output |
| Wait for elements | Use `sleep` |
| Assert content in index tests | Only check HTTP status |

## Common Mistakes

1. **Testing mocks** - You're testing nothing
2. **Mocking policies** - Use real authorized users
3. **Auth tests in request specs** - Move to policy specs
4. **`sleep` in system specs** - Use Capybara's waiting
5. **Deleting failing tests** - Fix the root cause

**Remember:** Tests verify behavior, not implementation.
