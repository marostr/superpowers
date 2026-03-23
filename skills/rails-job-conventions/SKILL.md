---
name: rails-job-conventions
description: Use when creating or modifying background jobs/workers, implementing async processing, or designing for idempotency and retries
---

# Rails Job Conventions

Jobs are thin dispatchers. They find a record and call a method or interactor — nothing more.

## Core Principles

1. **Idempotent** — Jobs MUST be safe to run multiple times. Sidekiq retries
2. **Thin** — Jobs orchestrate, they don't implement. Delegate to interactors or models
3. **Sidekiq workers** — Engine workers live under `app/workers/engine_name/`. Main app uses both `ApplicationJob` and direct Sidekiq workers
4. **Let errors raise** — Don't use `discard_on`. Fix root causes
5. **Pass IDs, not objects** — Serialization boundary

## Worker Pattern

```ruby
# Engine worker
module Operations
  class SyncGoalsWorker
    include Sidekiq::Job

    def perform(account_id)
      account = Account.find(account_id)
      return unless account.operations_engine_enabled?

      Operations::Goals::SyncOrganizer.perform(account:)
    end
  end
end
```

## Idempotency

```ruby
# WRONG - doubles credits on retry
def perform(user_id)
  user = User.find(user_id)
  user.credits += 100
  user.save!
end

# RIGHT - idempotent
def perform(credit_grant_id)
  grant = CreditGrant.find(credit_grant_id)
  return if grant.processed?
  grant.process!
end
```

## Thin Jobs

```ruby
# WRONG - fat job with business logic
def perform(order_id)
  order = Order.find(order_id)
  order.items.each { |i| i.reserve_inventory! }
  PaymentGateway.charge(order.total, order.payment_method)
  OrderMailer.confirmation(order).deliver_now
end

# RIGHT - delegate to interactor
def perform(order_id)
  order = Order.find(order_id)
  ProcessOrderOrganizer.perform(order:)
end
```

## Directory Structure

```
# Engine workers
engines/operations/app/workers/operations/
  sync_goals_worker.rb

# Main app jobs
app/jobs/
  application_job.rb
  ...
```

## Quick Reference

| Do | Don't |
|----|-------|
| Design for multiple runs | Assume single execution |
| Delegate to interactors | Business logic in jobs |
| Pass IDs as arguments | Pass serialized objects |
| Let errors raise | `discard_on` to hide failures |
| Check feature gate in engine workers | Assume engine is enabled |
| `find_each` for batch processing | `all.each` |

## Common Mistakes

1. **Non-idempotent operations** — Check state before mutating
2. **Fat jobs** — Move logic to interactors
3. **Silencing failures** — Let jobs fail, investigate root cause
4. **Missing feature gate** — Engine workers must check engine is enabled

**Remember:** Jobs are dispatchers, not implementers. They should be boring.
