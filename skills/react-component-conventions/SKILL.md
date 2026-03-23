---
name: react-component-conventions
description: Use when creating or modifying React components, hooks, contexts, or styled-components in the frontend
---

# React Component Conventions

Components are functional, typed, and composable. Business logic lives in hooks, UI primitives come from the design system, state flows through RTK Query and Redux.

## Core Principles

1. **Functional components only** — No class components. Ever
2. **Typed props** — Every component has a named props interface
3. **Hooks-first** — Business logic in custom hooks, not components
4. **Design system first** — Use Saguaro/design_system components before building custom UI
5. **Contexts for cross-cutting state** — Use React Context for feature-scoped shared state
6. **Styled-components for styling** — No inline styles, no CSS modules

## Component Structure

```typescript
// components/application/goals/GoalCard.tsx
import React from 'react';
import styled from 'styled-components';
import { Button } from '@design-system/buttons/Button';
import { useCurrentAccount } from '@hooks/useCurrentAccount';
import { Goal } from '@models/Goal';

interface GoalCardProps {
  goal: Goal;
  onEdit: (goalId: string) => void;
  isEditable?: boolean;
}

const GoalCard: React.FC<GoalCardProps> = ({ goal, onEdit, isEditable = false }) => {
  const { account } = useCurrentAccount();

  return (
    <CardWrapper>
      <h3>{goal.title}</h3>
      <p>{goal.description}</p>
      {isEditable && (
        <Button onClick={() => onEdit(goal.id)} label="Edit" />
      )}
    </CardWrapper>
  );
};

export default GoalCard;

const CardWrapper = styled.div`
  padding: 16px;
  border-radius: 8px;
  background: white;
`;
```

Key rules:
- Props interface above the component
- `React.FC<Props>` typing
- Default exports for page/feature components
- Named exports for shared utilities
- Styled components at the bottom of the file

## Directory Structure

```
components/
  design_system/          # Shared UI primitives (Saguaro)
    core/                 # CoreModal, CoreSelectField, etc.
    input/                # Form inputs
    buttons/              # Button variations
    overlays/             # Popovers, tooltips
  application/            # Feature-specific components
    goals/
    meetings/
    curriculums/
    home/
    editor/
  styled/                 # Styled-component wrappers
  shared/                 # Shared application components
```

## Custom Hooks

Extract business logic into custom hooks:

```typescript
// hooks/useGoals.ts
import { useGetGoalsQuery, useCreateGoalMutation } from '@redux/services/resourceApis/goals/goalsApi';

export const useGoals = (view: string) => {
  const { data, isLoading, error } = useGetGoalsQuery({ view });
  const [createGoal, { isLoading: isCreating }] = useCreateGoalMutation();

  return {
    goals: data?.data ?? [],
    isLoading,
    error,
    createGoal,
    isCreating,
  };
};
```

125+ custom hooks exist in `hooks/`. Check for existing hooks before creating new ones.

## Contexts

74 React Contexts provide feature-scoped shared state:

```typescript
// contexts/GoalEditorContext.tsx
interface GoalEditorContextValue {
  isEditing: boolean;
  setIsEditing: (value: boolean) => void;
  selectedGoalId: string | null;
}

const GoalEditorContext = React.createContext<GoalEditorContextValue | undefined>(undefined);

export const useGoalEditor = () => {
  const context = useContext(GoalEditorContext);
  if (!context) {
    throw new Error('useGoalEditor must be used within GoalEditorProvider');
  }
  return context;
};
```

Contexts live in `contexts/`. Use them for state that multiple sibling components need but doesn't belong in Redux.

## Redux Integration

Use typed hooks from `@redux/hooks`:

```typescript
// RIGHT — typed hooks
import { useAppDispatch, useAppSelector } from '@redux/hooks';

const dispatch = useAppDispatch();
const authSlug = useAppSelector((state) => state.auth.slug);

// WRONG — untyped hooks
import { useDispatch, useSelector } from 'react-redux';
```

## Styling

Styled-components is the styling approach:

```typescript
import styled from 'styled-components';

const Container = styled.div`
  display: flex;
  gap: 16px;
  padding: 24px;
`;

// With props
interface StyledProps {
  isActive: boolean;
}

const Tab = styled.button<StyledProps>`
  color: ${({ isActive }) => (isActive ? 'blue' : 'gray')};
`;
```

## Forms

Forms use Formik with Yup validation:

```typescript
import { Formik, Form, Field } from 'formik';
import * as Yup from 'yup';

const GoalSchema = Yup.object().shape({
  title: Yup.string().required('Title is required'),
  targetDate: Yup.date().nullable(),
});
```

## Quick Reference

| Do | Don't |
|----|-------|
| Functional components | Class components |
| Named props interface | Inline `{ prop: type }` |
| Custom hooks for logic | Business logic in components |
| Design system components | Custom UI when Saguaro has it |
| `useAppSelector`/`useAppDispatch` | Raw `useSelector`/`useDispatch` |
| Styled-components | Inline styles or CSS modules |
| Contexts for feature state | Prop drilling through 4+ levels |
| Check existing hooks first | Duplicate hook logic |
| `@`-prefixed imports | Deep relative paths |

## Common Mistakes

1. **Logic in components** — Extract to custom hooks
2. **Rebuilding design system components** — Check Saguaro/design_system first
3. **Prop drilling** — Use Context for deeply shared state
4. **Untyped props** — Always define a named interface
5. **Raw Redux hooks** — Use typed `useAppDispatch`/`useAppSelector`
6. **Missing error/loading states** — Handle `isLoading` and `error` from RTK Query hooks

**Remember:** Components render. Hooks think. The design system provides the building blocks.
