---
name: rails-job-conventions
description: Use when creating or modifying background jobs in app/jobs
---

# Rails Job Conventions

Conventions for background jobs in this project.

## When to Use This Skill

Automatically activates when working on:
- `app/jobs/**/*.rb`

Use this skill when:
- Creating new background jobs
- Modifying job logic
- Handling async processing

## Core Principle: Idempotency

Jobs MUST be safe to run multiple times with the same arguments.

Sidekiq retries failed jobs. Network blips happen. Workers crash. Your job will run again. Design for it.

**WRONG** - Not idempotent:
```ruby
def perform(user_id)
  user = User.find(user_id)
  user.credits += 100  # Doubles credits on retry!
  user.save!
  UserMailer.credits_added(user).deliver_now
end
```

**RIGHT** - Idempotent:
```ruby
def perform(user_id, credit_grant_id)
  grant = CreditGrant.find(credit_grant_id)
  return if grant.processed?  # Already done, skip

  grant.process!  # Model handles state transition atomically
end
```

## Inheritance

Always use `ApplicationJob`, not `Sidekiq::Job` directly:

```ruby
# WRONG
class MyJob
  include Sidekiq::Job
end

# RIGHT
class MyJob < ApplicationJob
  def perform(id)
    # ...
  end
end
```

## Thin Jobs

Jobs orchestrate, they don't implement. Delegate to models or service objects:

**WRONG** - Fat job:
```ruby
def perform(order_id)
  order = Order.find(order_id)
  order.status = :processing
  order.save!

  order.items.each do |item|
    item.reserve_inventory!
  end

  PaymentGateway.charge(order.total, order.payment_method)
  order.status = :completed
  order.save!

  OrderMailer.confirmation(order).deliver_now
end
```

**RIGHT** - Thin job:
```ruby
def perform(order_id)
  order = Order.find(order_id)
  order.process!  # Model handles the workflow
end
```

## Error Handling

- **Let errors raise** - Sidekiq retries handle transient failures
- **Don't use `discard_on`** - Fix the root cause instead
- **Default retry behavior is fine** - Don't over-configure

```ruby
# WRONG - hiding failures
class MyJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound  # Don't do this

# RIGHT - let it fail, investigate, fix
class MyJob < ApplicationJob
  def perform(id)
    record = Record.find(id)  # If not found, job fails, you investigate
    record.process!
  end
end
```

## Performance

1. **Batch with `find_each`**:
   ```ruby
   # WRONG
   User.all.each { |u| process(u) }

   # RIGHT
   User.find_each { |u| process(u) }
   ```

2. **Avoid N+1s**:
   ```ruby
   # WRONG
   Order.find_each { |o| puts o.items.count }

   # RIGHT
   Order.includes(:items).find_each { |o| puts o.items.count }
   ```

3. **Pass IDs, not objects**:
   ```ruby
   # WRONG - serializes entire object
   MyJob.perform_later(user)

   # RIGHT - just the ID
   MyJob.perform_later(user.id)
   ```

4. **Split large work**:
   ```ruby
   # For processing many records, enqueue individual jobs
   User.find_each do |user|
     ProcessUserJob.perform_later(user.id)
   end
   ```

## Job Structure Template

```ruby
class ProcessOrderJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)
    order.process!
  end
end
```

## Quick Reference

| Do | Don't |
|----|-------|
| Design for multiple runs | Assume single execution |
| `< ApplicationJob` | `include Sidekiq::Job` |
| Delegate to models | Business logic in jobs |
| Pass IDs as arguments | Pass serialized objects |
| `find_each` for batches | `all.each` |
| Let errors raise | `discard_on` to hide failures |
| Check state before mutating | Assume clean state |

## Common Mistakes

1. **Non-idempotent operations** - Check state, use constraints
2. **Fat jobs** - Move logic to models
3. **Mixed inheritance** - Always use ApplicationJob
4. **Silencing failures** - Let jobs fail, fix root cause
5. **Memory bloat** - Use find_each, pass IDs

**Remember:** Jobs are dispatchers, not implementers. They should be boring.
