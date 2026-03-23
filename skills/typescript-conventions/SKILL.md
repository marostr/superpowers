---
name: typescript-conventions
description: Use when creating or modifying TypeScript files, defining types/interfaces, or working with type safety patterns in the React frontend
---

# TypeScript Conventions

TypeScript is used strictly across the React frontend. Explicit types, no implicit `any`, strict null checks.

## Core Principles

1. **Strict mode enforced** — `noImplicitAny`, `strictNullChecks`, `noUnusedLocals` are all enabled
2. **Explicit interfaces** — Every component, hook, and function has typed parameters and return types
3. **Use path aliases** — Import with `@`-prefixed aliases, never relative paths that traverse up more than one level
4. **No `any`** — Use `unknown` if the type is truly unknown, then narrow. Never cast to `any` to silence errors

## Path Aliases

The project uses `@`-prefixed path aliases defined in `tsconfig.json`:

```typescript
// RIGHT — use aliases
import { Button } from '@design-system/buttons/Button';
import { useCurrentAccount } from '@hooks/useCurrentAccount';
import { trainualApi } from '@redux/services/trainualService';
import { AccountState } from '@types/AccountState';
import { toCamelCase } from '@lib/keyFormatConverter';

// WRONG — deep relative paths
import { Button } from '../../../design_system/buttons/Button';
import { useCurrentAccount } from '../../../../hooks/useCurrentAccount';
```

Available aliases: `@components/*`, `@hooks/*`, `@redux/*`, `@types/*`, `@models/*`, `@lib/*`, `@design-system/*`, `@contexts/*`, `@constants/*`, `@images/*`

## Type Definitions

Types live in dedicated locations:

```
react/types/          # Shared type definitions (105+ files)
  jsonapi/            # JSON:API spec types
  AccountState.ts     # Domain-specific types
  ...
react/models/         # Data model types (31 files)
```

### Interface Patterns

```typescript
// Component props — always an interface
interface GoalCardProps {
  goal: Goal;
  onEdit: (goalId: string) => void;
  isEditable?: boolean;
}

// API response types
interface GoalApiResponse {
  data: JsonApiResource<GoalAttributes, GoalMeta>;
}

// Union types for discriminated state
type GoalStatus = 'on_track' | 'off_track' | 'at_risk' | 'not_started';
```

### Generic Types

```typescript
// RTK Query endpoint typing
builder.query<GoalResponse, number>({
  query: (goalId) => `goals/${goalId}`,
  transformResponse: (response: GoalApiResponse) => toCamelCase(response),
})
```

## Strict Null Checks

```typescript
// WRONG — assumes value exists
const name = user.profile.name;

// RIGHT — handle nullability
const name = user.profile?.name ?? 'Unknown';

// RIGHT — guard clause
if (!user.profile) {
  return null;
}
const name = user.profile.name;
```

## Quick Reference

| Do | Don't |
|----|-------|
| Explicit interfaces for props | Inline object types |
| `@`-prefixed path aliases | Deep relative imports (`../../..`) |
| `unknown` + type narrowing | `any` to silence errors |
| Union types for variants | Strings or enums for simple sets |
| Optional chaining (`?.`) | Unchecked property access |
| Types in `types/` or `models/` | Inline type definitions scattered across files |
| Generic type parameters | Casting with `as` to force types |

## Common Mistakes

1. **Using `any`** — Use `unknown` and narrow, or define a proper type
2. **Deep relative imports** — Use path aliases
3. **Missing null checks** — `strictNullChecks` is enabled, handle it
4. **Unused variables** — `noUnusedLocals` will error, remove or prefix with `_`
5. **Inline types for props** — Extract to a named interface

**Remember:** Strict TypeScript. Explicit types. Path aliases. No `any`.
