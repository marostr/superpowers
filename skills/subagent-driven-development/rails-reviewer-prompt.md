# Rails Conventions Reviewer Prompt Template

Use this template when dispatching a Rails conventions reviewer subagent.

**Purpose:** Verify implementation follows project's Rails conventions

**Only dispatch for Rails projects, after spec compliance review passes.**

```
Task tool (superpowers:rails-reviewer):
  Use agent at agents/rails-reviewer.md

  FILES_CHANGED: [list of files from this task]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**Rails reviewer returns:** ✅ Conventions followed, or ❌ violations with file:line references
