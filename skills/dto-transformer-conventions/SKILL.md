---
name: dto-transformer-conventions
description: Use when creating or modifying TypeScript type definitions, JSON:API response types, data models, or the key-case transformation layer
---

# DTO & Transformer Conventions

The frontend maintains a strict boundary between API response shapes (snake_case, JSON:API) and frontend data types (camelCase, domain models). Type definitions and transformers enforce this boundary.

## Core Principles

1. **API types mirror the backend** — DTO types match the JSON:API response shape exactly (snake_case keys)
2. **Entity types are the frontend contract** — camelCase, flattened, ready for component consumption
3. **Transform once at the boundary** — `toCamelCase`/`toSnakeCase` in RTK Query, never in components
4. **Types live in dedicated directories** — `types/` for shared types, `models/` for domain models

## Type Architecture

```
types/                          # Shared type definitions
  jsonapi/
    jsonapi.ts                  # JSON:API spec types (generic)
  GoalTypes.ts                  # Goal-specific API + entity types
  AccountState.ts               # Account state shape
  ...

models/                         # Domain model types
  Goal.ts
  Meeting.ts
  User.ts
  ...
```

## JSON:API Type Definitions

The project has generic JSON:API types that all API response types build on:

```typescript
// types/jsonapi/jsonapi.ts
interface JsonApiResource<TAttributes, TMeta = Record<string, unknown>> {
  id: string;
  type: string;
  attributes: TAttributes;
  relationships?: Record<string, JsonApiRelationship>;
  meta?: TMeta;
}

interface JsonApiResponse<T> {
  data: T;
  included?: JsonApiResource[];
  meta?: Record<string, unknown>;
  links?: JsonApiLinks;
}

interface JsonApiCollectionResponse<T> {
  data: T[];
  included?: JsonApiResource[];
  meta?: JsonApiPaginationDTO;
  links?: JsonApiLinks;
}

interface JsonApiPaginationDTO {
  totalCount: number;
  page: number;
  perPage: number;
}
```

## DTO vs Entity Pattern

For each API resource, define both the API response shape and the frontend entity:

```typescript
// types/GoalTypes.ts

// API response attributes (matches backend serializer output after toCamelCase)
interface GoalAttributes {
  title: string;
  description: string | null;
  targetDate: string | null;  // ISO8601
  companyVisible: boolean;
  createdAt: string;          // ISO8601
}

// Meta from serializer (permissions, computed status)
interface GoalMeta {
  status: GoalStatus;
  canEdit: boolean;
  canDelete: boolean;
  canTransferOwnership: boolean;
}

// Full API response types
type GoalResource = JsonApiResource<GoalAttributes, GoalMeta>;
type GoalApiResponse = JsonApiResponse<GoalResource>;
type GoalsApiResponse = JsonApiCollectionResponse<GoalResource>;

// Frontend entity (flattened for component use)
interface Goal {
  id: string;
  title: string;
  description: string | null;
  targetDate: string | null;
  companyVisible: boolean;
  createdAt: string;
  status: GoalStatus;
  canEdit: boolean;
  canDelete: boolean;
}

type GoalStatus = 'on_track' | 'off_track' | 'at_risk' | 'not_started';
```

## Key Format Converter

The transformer layer is centralized in `lib/keyFormatConverter.ts`:

```typescript
import { toCamelCase, toSnakeCase } from '@lib/keyFormatConverter';

// API response (snake_case) → frontend (camelCase)
const frontendData = toCamelCase(apiResponse);
// { target_date: "2026-06-30" } → { targetDate: "2026-06-30" }

// Frontend (camelCase) → API request (snake_case)
const requestParams = toSnakeCase(frontendData);
// { targetDate: "2026-06-30" } → { target_date: "2026-06-30" }
```

**This transformation happens ONLY in RTK Query `transformResponse` and request `params`/`body`.** Never transform in components or hooks.

## Model Types

Domain models in `models/` represent the core business entities used across the app:

```typescript
// models/Goal.ts
export interface Goal {
  id: string;
  title: string;
  description: string | null;
  targetDate: string | null;
  status: GoalStatus;
  ownerId: string;
  accountId: number;
}
```

These are the types components import and work with — not the raw JSON:API response types.

## Pagination Types

```typescript
interface JsonApiPaginationDTO {
  totalCount: number;
  page: number;
  perPage: number;
}

// Used in list response handling:
interface PaginatedGoalsResponse {
  data: Goal[];
  pagination: JsonApiPaginationDTO;
}
```

## Quick Reference

| Do | Don't |
|----|-------|
| Define API types matching serializer output | Guess the response shape |
| `toCamelCase` at RTK Query boundary | Transform in components |
| Separate DTO (API) and entity (frontend) types | One type for everything |
| Types in `types/` and `models/` | Inline types in component files |
| Use JSON:API generic types | Redefine `data`/`attributes` structure |
| Union types for status enums | Raw strings |
| `string \| null` for optional API fields | Omit nullability |

## Common Mistakes

1. **Transforming in components** — `toCamelCase`/`toSnakeCase` belongs in RTK Query only
2. **Missing null types** — API fields can be `null`, type them accordingly
3. **Using API types in components** — Components use entity types, not raw JSON:API shapes
4. **Scattered type definitions** — Keep types in `types/` and `models/`
5. **Forgetting meta types** — Serializer meta (permissions, status) needs its own interface
6. **String instead of union type** — Use `type Status = 'active' | 'inactive'` not `string`

**Remember:** API types in, entity types out. Transform once at the boundary. Types have a home.
