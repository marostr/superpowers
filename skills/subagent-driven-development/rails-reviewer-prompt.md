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

**Rails reviewer returns:** Severity-classified results:
- Conventions followed well (specific good patterns observed)
- Critical/Important/Suggestion issues with `file:line` references and idiomatic fixes
- Summary: ✅ conventions followed, or ❌ N critical, N important, N suggestions
