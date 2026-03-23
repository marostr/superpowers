---
name: frontend-testing-conventions
description: Use when creating or modifying frontend tests with Vitest, React Testing Library, or MSW mocks
---

# Frontend Testing Conventions

Frontend tests use Vitest + React Testing Library + MSW. Test behavior, not implementation.

## Core Principles

1. **Test behavior, not implementation** — Test what the user sees and does, not internal state
2. **MSW for API mocking** — Mock Service Worker intercepts network requests, no manual fetch mocking
3. **React Testing Library queries** — Use accessible queries (`getByRole`, `getByLabelText`), avoid `getByTestId`
4. **No console pollution** — `vitest-fail-on-console` is enabled. Capture expected errors
5. **Component tests over unit tests** — Render the component, interact with it, assert the output

## Test Structure

```typescript
// components/application/goals/GoalCard.test.tsx
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { render } from '@test-helpers/render';
import GoalCard from './GoalCard';
import { goalFactory } from '@test-helpers/factories/goalFactory';

describe('GoalCard', () => {
  const goal = goalFactory.build({ title: 'Q1 Revenue Target' });

  it('renders the goal title', () => {
    render(<GoalCard goal={goal} onEdit={vi.fn()} />);

    expect(screen.getByText('Q1 Revenue Target')).toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', async () => {
    const onEdit = vi.fn();
    const user = userEvent.setup();

    render(<GoalCard goal={goal} onEdit={onEdit} isEditable />);

    await user.click(screen.getByRole('button', { name: /edit/i }));

    expect(onEdit).toHaveBeenCalledWith(goal.id);
  });

  it('hides edit button when not editable', () => {
    render(<GoalCard goal={goal} onEdit={vi.fn()} isEditable={false} />);

    expect(screen.queryByRole('button', { name: /edit/i })).not.toBeInTheDocument();
  });
});
```

## MSW API Mocking

Mock API responses with MSW handlers:

```typescript
// components/tests/server/handlers/goals.ts
import { http, HttpResponse } from 'msw';

export const goalHandlers = [
  http.get('*/operations/api/goals', () => {
    return HttpResponse.json({
      data: [
        {
          id: '1',
          type: 'goal',
          attributes: { title: 'Test Goal', target_date: '2026-06-30' },
          meta: { status: 'on_track', can_edit: true },
        },
      ],
      meta: { total_count: 1, page: 1, per_page: 25 },
    });
  }),

  http.post('*/operations/api/goals', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json(
      {
        data: {
          id: '2',
          type: 'goal',
          attributes: body.data.attributes,
        },
      },
      { status: 201 }
    );
  }),
];
```

MSW server is set up in `components/tests/server/server.ts` and runs for all tests via `setupTests.js`.

## Query Priority

Use accessible queries in this order (React Testing Library best practices):

1. `getByRole` — buttons, links, headings, etc.
2. `getByLabelText` — form inputs
3. `getByPlaceholderText` — inputs without labels
4. `getByText` — visible text content
5. `getByDisplayValue` — current input values
6. `getByTestId` — **last resort only**

```typescript
// RIGHT — accessible queries
screen.getByRole('button', { name: /save/i })
screen.getByLabelText('Goal title')
screen.getByText('Q1 Revenue Target')

// WRONG — test IDs when accessible query exists
screen.getByTestId('save-button')
screen.getByTestId('goal-title-input')
```

## Async Testing

```typescript
// Wait for loading to complete
await waitFor(() => {
  expect(screen.getByText('Q1 Revenue Target')).toBeInTheDocument();
});

// Wait for element to disappear
await waitFor(() => {
  expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
});

// User interactions are async
const user = userEvent.setup();
await user.click(screen.getByRole('button', { name: /submit/i }));
await user.type(screen.getByLabelText('Title'), 'New Goal');
```

## Test File Location

Tests live alongside their components:

```
components/application/goals/
  GoalCard.tsx
  GoalCard.test.tsx
  GoalsList.tsx
  GoalsList.test.tsx
```

## Vitest Utilities

```typescript
// Mock functions
const onEdit = vi.fn();

// Mock timers
vi.useFakeTimers();
vi.advanceTimersByTime(1000);
vi.useRealTimers();

// Spy on module
vi.spyOn(hooks, 'useCurrentAccount').mockReturnValue({ account });
```

## Storybook

Components should have Storybook stories alongside tests:

```typescript
// GoalCard.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import GoalCard from './GoalCard';

const meta: Meta<typeof GoalCard> = {
  title: 'Application/Goals/GoalCard',
  component: GoalCard,
};
export default meta;

type Story = StoryObj<typeof GoalCard>;

export const Default: Story = {
  args: {
    goal: { id: '1', title: 'Q1 Revenue', status: 'on_track' },
    onEdit: () => {},
  },
};

export const Editable: Story = {
  args: {
    ...Default.args,
    isEditable: true,
  },
};
```

## Quick Reference

| Do | Don't |
|----|-------|
| `getByRole`, `getByLabelText` | `getByTestId` when accessible query exists |
| MSW for API mocking | Manual fetch/axios mocking |
| `userEvent.setup()` for interactions | `fireEvent` for user actions |
| `waitFor` for async assertions | `setTimeout` or manual delays |
| `vi.fn()` for mock functions | Jest's `jest.fn()` |
| Test files alongside components | Separate test directories |
| Test behavior (what user sees) | Test implementation (state, hooks) |

## Common Mistakes

1. **Using `getByTestId` first** — Use accessible queries; `getByTestId` is last resort
2. **Manual fetch mocking** — Use MSW handlers
3. **`fireEvent` for user actions** — Use `userEvent` (closer to real behavior)
4. **Missing `await` on user interactions** — `userEvent` methods are async
5. **Console errors in tests** — `vitest-fail-on-console` will fail the test, handle expected errors
6. **Testing implementation** — Don't assert on internal state or hook calls, assert on rendered output

**Remember:** Test what the user sees. Mock at the network layer. Use accessible queries.
