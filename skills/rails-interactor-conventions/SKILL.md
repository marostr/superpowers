---
name: rails-interactor-conventions
description: Use when creating or modifying interactors, organizers, or context classes for business logic operations
---

# Rails Interactor Conventions

All business logic lives in interactors. Controllers delegate to them. Models don't contain multi-step operations.

## Core Principles

1. **Single responsibility** — One interactor does one thing
2. **Organizers orchestrate** — Multi-step operations use `TransactionOrganizer` to compose interactors
3. **Context is the contract** — Context classes define inputs, outputs, and validations
4. **Fail explicitly** — Call `context.fail!(errors)` to halt execution and trigger rollback
5. **Hooks for side effects** — Notifications, analytics, and async work go in `after_success` hooks

## Architecture

```
Controller
  └─ calls Organizer.perform(context_params)
       └─ wraps in DB transaction
            ├─ Interactor 1 (e.g., CreateMetric)
            ├─ Interactor 2 (e.g., CreateGoal)
            ├─ Interactor 3 (e.g., CreateGoalOwner)
            └─ Interactor 4 (e.g., CreateObservation)
       └─ after_success: send notifications
```

## Single Interactors

Each interactor performs one atomic operation:

```ruby
module Operations
  module Goals
    class CreateGoal < DeferredInteractor
      def perform
        context.goal = Operations::Goal.new(goal_params)
        context.fail!(context.goal.errors) unless context.goal.save
      end

      private

      def goal_params
        {
          account: context.account,
          title: context.params[:title],
          description: context.params[:description],
          target_date: context.params[:target_date],
          created_by: context.user
        }
      end
    end
  end
end
```

Key rules:
- Inherit from `DeferredInteractor` (or `BaseInteractor` for main app)
- Access inputs via `context.attribute_name`
- Set outputs on context: `context.goal = ...`
- Fail with `context.fail!(errors)` — this halts the organizer chain and triggers rollback

## Organizers

Organizers compose interactors into a transactional unit:

```ruby
module Operations
  module Goals
    class CreateGoalOrganizer < TransactionOrganizer
      include Operations::GoalNotifiable

      after_success :send_notifications

      organize do
        add Operations::Goals::CreateMetric
        add Operations::Goals::CreateGoal
        add Operations::Goals::CreateGoalOwner
        add Operations::Goals::CreateObservation
        add Operations::Goals::CreateGoalWatchers
      end
    end
  end
end
```

Key rules:
- Inherit from `TransactionOrganizer` — wraps all steps in a DB transaction
- `organize do ... end` defines the step sequence
- If any step fails, the transaction rolls back all previous steps
- Side effects (notifications, analytics) go in `after_success` — never in individual interactors

## Context Classes

Context classes define the contract between organizer and interactors:

```ruby
module Operations
  module Goals
    class CreateGoalOrganizerContext < BaseContext
      input_attributes :params, :account, :user
      output_attributes :goal, :metric, :observation

      validates :params, :account, :user, presence: true, on: :calling
      validates :goal, :metric, :observation, presence: true, on: :called
    end
  end
end
```

- `input_attributes` — what the caller must provide
- `output_attributes` — what the organizer produces
- `on: :calling` — validated before execution
- `on: :called` — validated after execution

## Calling from Controllers

```ruby
def create
  authorize Goal
  result = CreateGoalOrganizer.perform(
    params: jsonapi_params,
    account: current_account,
    user: current_user
  )

  if result.success?
    render_jsonapi_response(result.goal, status: :created)
  else
    collect_jsonapi_error(result.errors)
    render_jsonapi_response(result.goal || Goal.new)
  end
end
```

Always check `result.success?` — never assume success.

## Directory Structure

```
app/interactors/
  operations/
    goals/
      create_goal.rb
      create_goal_organizer.rb
      create_goal_organizer_context.rb
      create_metric.rb
      create_goal_owner.rb
      create_observation.rb
      create_goal_watchers.rb
      update_goal.rb
      update_goal_organizer.rb
      archive_goal.rb
    meetings/
      create_meeting.rb
      create_meeting_organizer.rb
      ...
```

Group by domain, then by operation. Each organizer gets its own context class.

## Brownfield Reality

The main app has 808+ interactor files with mixed patterns. Some older interactors:
- Don't use context classes
- Don't use `TransactionOrganizer`
- Mix concerns that should be separate

When modifying existing interactors, follow the patterns already in that file. For new work, always use the clean pattern: context class + `TransactionOrganizer` + single-responsibility interactors.

## Quick Reference

| Do | Don't |
|----|-------|
| One interactor = one operation | Fat interactors doing multiple things |
| `TransactionOrganizer` for multi-step | Manual `ActiveRecord::Base.transaction` |
| Context classes with validations | Untyped context bags |
| `after_success` for side effects | Notifications inside interactors |
| `context.fail!(errors)` to halt | Raise exceptions for business logic |
| Check `result.success?` in controller | Assume organizer succeeded |
| Group by domain in directory structure | Flat interactor directories |

## Common Mistakes

1. **Fat interactors** — If an interactor does more than one thing, split it
2. **Side effects in interactors** — Notifications, emails, analytics go in organizer `after_success` hooks
3. **Missing context class** — New organizers must define input/output contracts
4. **Not using TransactionOrganizer** — Multi-step writes must be transactional
5. **Business logic in controllers** — Delegate to interactors, always
6. **Business logic in models** — Multi-step operations belong in interactors, not model methods

**Remember:** Interactors are the logic layer. Models own data. Controllers delegate.
