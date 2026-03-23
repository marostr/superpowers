---
name: rtk-query-conventions
description: Use when creating or modifying RTK Query API endpoints, cache invalidation, or data fetching patterns
---

# RTK Query Conventions

All API data fetching uses RTK Query via `@reduxjs/toolkit`. Endpoints are defined with `injectEndpoints`, responses are transformed at the boundary, and cache is managed via tags.

## Core Principles

1. **RTK Query for all API calls** — No raw `fetch` or `axios` in components. All data fetching through RTK Query endpoints
2. **Transform at the boundary** — `transformResponse` converts snake_case API responses to camelCase frontend types
3. **Tag-based cache invalidation** — Every query provides tags, every mutation invalidates them
4. **Inject endpoints** — Use `trainualApi.injectEndpoints()` in domain-specific files, not one giant API definition

## API Service Architecture

```
redux/services/
  trainualService.ts       # Base API with createApi, tag types
  resourceApis/            # 87+ domain-specific endpoint files
    goals/
    meetings/
    userRoles/
    curriculums/
    ...
  baseQueries/
    dynamicBaseQuery.ts    # Custom base query with auth/slug injection
```

## Endpoint Pattern

```typescript
// redux/services/resourceApis/goals/goalsApi.ts
import { trainualApi } from '@redux/services/trainualService';
import { toCamelCase, toSnakeCase } from '@lib/keyFormatConverter';

const goalsApi = trainualApi.injectEndpoints({
  endpoints: (builder) => ({
    getGoals: builder.query<GoalsResponse, GetGoalsParams>({
      query: (params) => ({
        url: 'operations/api/goals',
        method: 'GET',
        params: toSnakeCase(params),
      }),
      providesTags: (result) =>
        result
          ? [
              ...result.data.map(({ id }) => ({ type: 'Goal' as const, id })),
              { type: 'Goal', id: 'LIST' },
            ]
          : [{ type: 'Goal', id: 'LIST' }],
      transformResponse: (response: GoalsApiResponse) => toCamelCase(response),
    }),

    createGoal: builder.mutation<GoalResponse, CreateGoalParams>({
      query: (params) => ({
        url: 'operations/api/goals',
        method: 'POST',
        body: { data: { attributes: toSnakeCase(params) } },
      }),
      invalidatesTags: [{ type: 'Goal', id: 'LIST' }],
      transformResponse: (response: GoalApiResponse) => toCamelCase(response),
    }),

    updateGoal: builder.mutation<GoalResponse, UpdateGoalParams>({
      query: ({ id, ...params }) => ({
        url: `operations/api/goals/${id}`,
        method: 'PATCH',
        body: { data: { attributes: toSnakeCase(params) } },
      }),
      invalidatesTags: (_result, _error, { id }) => [
        { type: 'Goal', id },
        { type: 'Goal', id: 'LIST' },
      ],
      transformResponse: (response: GoalApiResponse) => toCamelCase(response),
    }),

    deleteGoal: builder.mutation<void, string>({
      query: (id) => ({
        url: `operations/api/goals/${id}`,
        method: 'DELETE',
      }),
      invalidatesTags: [{ type: 'Goal', id: 'LIST' }],
    }),
  }),
});

export const {
  useGetGoalsQuery,
  useCreateGoalMutation,
  useUpdateGoalMutation,
  useDeleteGoalMutation,
} = goalsApi;
```

## Key Transformation

All API communication crosses a snake_case/camelCase boundary:

```typescript
import { toCamelCase, toSnakeCase } from '@lib/keyFormatConverter';

// Outgoing request params → snake_case
query: (params) => ({
  url: 'api/endpoint',
  params: toSnakeCase(params),  // { targetDate } → { target_date }
})

// Incoming response → camelCase
transformResponse: (response: ApiResponse) => toCamelCase(response)
// { target_date } → { targetDate }
```

**Every endpoint must use `transformResponse` with `toCamelCase`.** Never use raw snake_case data in components.

**Every outgoing request with params/body must use `toSnakeCase`.** The Rails backend expects snake_case.

## JSON:API Request Body

For POST/PATCH requests to JSON:API endpoints, wrap params in the JSON:API structure:

```typescript
body: {
  data: {
    attributes: toSnakeCase(params)
  }
}
```

## Cache Tags

The project uses 100+ tag types. Follow these patterns:

```typescript
// Query provides tags for cache identification
providesTags: (result) =>
  result?.data
    ? [
        ...result.data.map(({ id }) => ({ type: 'Goal' as const, id })),
        { type: 'Goal', id: 'LIST' },
      ]
    : [{ type: 'Goal', id: 'LIST' }],

// Mutation invalidates tags to trigger refetch
invalidatesTags: [{ type: 'Goal', id: 'LIST' }],

// Targeted invalidation for updates
invalidatesTags: (_result, _error, { id }) => [
  { type: 'Goal', id },
  { type: 'Goal', id: 'LIST' },
],
```

## Using Hooks in Components

```typescript
const GoalsList: React.FC = () => {
  const { data, isLoading, error } = useGetGoalsQuery({ view: 'my_goals' });
  const [createGoal, { isLoading: isCreating }] = useCreateGoalMutation();

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <div>
      {data?.data.map((goal) => (
        <GoalCard key={goal.id} goal={goal} />
      ))}
    </div>
  );
};
```

## Redux Hooks

Always use the typed hooks, never raw `useDispatch`/`useSelector`:

```typescript
// RIGHT
import { useAppDispatch, useAppSelector } from '@redux/hooks';

// WRONG
import { useDispatch, useSelector } from 'react-redux';
```

## Quick Reference

| Do | Don't |
|----|-------|
| `trainualApi.injectEndpoints()` | One giant API file |
| `toCamelCase` in `transformResponse` | Use raw snake_case in components |
| `toSnakeCase` for outgoing params | Send camelCase to Rails |
| `providesTags` on every query | Queries without cache tags |
| `invalidatesTags` on every mutation | Manual cache updates |
| Export generated hooks | Call `dispatch(api.endpoints...)` directly |
| `useAppDispatch` / `useAppSelector` | Raw `useDispatch` / `useSelector` |
| JSON:API body structure for POST/PATCH | Flat params body |

## Common Mistakes

1. **Missing transformResponse** — Raw snake_case data leaks into components
2. **Missing toSnakeCase** — camelCase params confuse the Rails backend
3. **No cache tags** — Stale data after mutations
4. **Raw fetch/axios in components** — Always use RTK Query endpoints
5. **Untyped endpoints** — Always provide request and response generics
6. **Raw Redux hooks** — Use `useAppDispatch`/`useAppSelector` for type safety

**Remember:** Transform at the boundary. Tags for cache. Inject endpoints per domain.
