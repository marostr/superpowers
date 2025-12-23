---
name: rails-job-conventions
description: Use when creating or modifying background jobs in app/jobs
---

# Rails Job Conventions

Conventions for background jobs in this project.

## Core Principles

1. **Idempotent** - Jobs MUST be safe to run multiple times. Sidekiq retries.
2. **Thin** - Jobs orchestrate, they don't implement. Delegate to models.
3. **ApplicationJob** - Always inherit from ApplicationJob, not Sidekiq::Job
4. **Let errors raise** - Don't use `discard_on`. Fix root causes.

## Idempotency (Critical)

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

# RIGHT - thin job
def perform(order_id)
  Order.find(order_id).process!
end
```

## Performance

- **Pass IDs, not objects** - `MyJob.perform_later(user.id)` not `perform_later(user)`
- **Use `find_each`** - Not `all.each`
- **Split large work** - Enqueue individual jobs per record

## Quick Reference

| Do | Don't |
|----|-------|
| Design for multiple runs | Assume single execution |
| `< ApplicationJob` | `include Sidekiq::Job` |
| Delegate to models | Business logic in jobs |
| Pass IDs as arguments | Pass serialized objects |
| Let errors raise | `discard_on` to hide failures |

## Common Mistakes

1. **Non-idempotent operations** - Check state before mutating
2. **Fat jobs** - Move logic to models
3. **Silencing failures** - Let jobs fail, investigate root cause

**Remember:** Jobs are dispatchers, not implementers. They should be boring.
