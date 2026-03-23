#!/bin/bash
# PreToolUse hook: Enforce convention skills when editing Rails or frontend files
# Uses deny-until-skill-loaded pattern - blocks edits until required skill is loaded

LOG_FILE="/tmp/claude-skill-usage.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
  echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Read JSON input from stdin
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
skill_name=$(echo "$input" | jq -r '.tool_input.skill // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

log "HOOK START: tool=$tool_name path=$file_path skill=$skill_name"

# Log skill usage - always allow Skill tool
if [[ "$tool_name" == "Skill" && -n "$skill_name" ]]; then
  log "BRANCH: Skill tool -> loaded: $skill_name"
  exit 0
fi

# Exit early if no file_path (not a file operation)
if [[ -z "$file_path" ]]; then
  log "BRANCH: No file_path -> exit early"
  exit 0
fi

# Function to check if skill was loaded in transcript
skill_loaded() {
  local skill="$1"
  if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    if grep -q "\"skill\": \"$skill\"" "$transcript_path" 2>/dev/null || \
       grep -q "\"skill\":\"$skill\"" "$transcript_path" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# Function to deny with message - uses exit code 2 to block
deny_without_skill() {
  local skill="$1"
  local file_type="$2"

  log "BRANCH: $file_type matched -> DENIED (skill $skill not loaded)"

  cat >&2 << EOF
BLOCKED: You must load the $skill skill before editing $file_type files.

STOP. Do not immediately retry your edit.
1. Load the skill: Skill(skill: "$skill")
2. Read the conventions carefully
3. Reconsider whether your planned edit follows them
4. Adjust your approach if needed, then edit
EOF
  exit 2
}

# Function to allow after skill loaded
allow_with_skill() {
  local skill="$1"
  local file_type="$2"

  log "BRANCH: $file_type matched -> ALLOWED (skill $skill already loaded)"
  exit 0
}

# Check if this is a Rails controller file
if [[ "$file_path" == */app/controllers/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-controller-conventions"; then
    allow_with_skill "superpowers-trainual:rails-controller-conventions" "controller"
  else
    deny_without_skill "superpowers-trainual:rails-controller-conventions" "controller"
  fi
  exit 0
fi

# Check if this is a Rails model file
if [[ "$file_path" == */app/models/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-model-conventions"; then
    allow_with_skill "superpowers-trainual:rails-model-conventions" "model"
  else
    deny_without_skill "superpowers-trainual:rails-model-conventions" "model"
  fi
  exit 0
fi

# Check if this is an interactor file
if [[ "$file_path" == */app/interactors/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-interactor-conventions"; then
    allow_with_skill "superpowers-trainual:rails-interactor-conventions" "interactor"
  else
    deny_without_skill "superpowers-trainual:rails-interactor-conventions" "interactor"
  fi
  exit 0
fi

# Check if this is a serializer file
if [[ "$file_path" == */app/serializers/*.rb ]]; then
  if skill_loaded "superpowers-trainual:jsonapi-conventions"; then
    allow_with_skill "superpowers-trainual:jsonapi-conventions" "serializer"
  else
    deny_without_skill "superpowers-trainual:jsonapi-conventions" "serializer"
  fi
  exit 0
fi

# Check if this is a query object file
if [[ "$file_path" == */app/queries/*.rb ]]; then
  if skill_loaded "superpowers-trainual:query-object-conventions"; then
    allow_with_skill "superpowers-trainual:query-object-conventions" "query object"
  else
    deny_without_skill "superpowers-trainual:query-object-conventions" "query object"
  fi
  exit 0
fi

# Check if this is a worker file
if [[ "$file_path" == */app/workers/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-job-conventions"; then
    allow_with_skill "superpowers-trainual:rails-job-conventions" "worker"
  else
    deny_without_skill "superpowers-trainual:rails-job-conventions" "worker"
  fi
  exit 0
fi

# Check if this is a Rails view file
if [[ "$file_path" == */app/views/*.erb ]]; then
  if skill_loaded "superpowers-trainual:rails-view-conventions"; then
    allow_with_skill "superpowers-trainual:rails-view-conventions" "view"
  else
    deny_without_skill "superpowers-trainual:rails-view-conventions" "view"
  fi
  exit 0
fi

# Check if this is a Rails helper file (prohibited - should migrate to ViewComponents)
if [[ "$file_path" == */app/helpers/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-view-conventions"; then
    allow_with_skill "superpowers-trainual:rails-view-conventions" "helper"
  else
    deny_without_skill "superpowers-trainual:rails-view-conventions" "helper"
  fi
  exit 0
fi

# Check if this is a ViewComponent file (Ruby, not Stimulus JS)
if [[ "$file_path" == */app/components/*.rb ]] && [[ "$file_path" != *_controller.js ]]; then
  if skill_loaded "superpowers-trainual:rails-view-conventions"; then
    allow_with_skill "superpowers-trainual:rails-view-conventions" "ViewComponent"
  else
    deny_without_skill "superpowers-trainual:rails-view-conventions" "ViewComponent"
  fi
  exit 0
fi

# Check if this is a Stimulus controller file
if [[ "$file_path" == */app/components/*_controller.js ]] || [[ "$file_path" == */app/packs/controllers/*_controller.js ]]; then
  if skill_loaded "superpowers-trainual:rails-stimulus-conventions"; then
    allow_with_skill "superpowers-trainual:rails-stimulus-conventions" "Stimulus controller"
  else
    deny_without_skill "superpowers-trainual:rails-stimulus-conventions" "Stimulus controller"
  fi
  exit 0
fi

# Check if this is a Rails policy file
if [[ "$file_path" == */app/policies/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-policy-conventions"; then
    allow_with_skill "superpowers-trainual:rails-policy-conventions" "policy"
  else
    deny_without_skill "superpowers-trainual:rails-policy-conventions" "policy"
  fi
  exit 0
fi

# Check if this is a Rails job file
if [[ "$file_path" == */app/jobs/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-job-conventions"; then
    allow_with_skill "superpowers-trainual:rails-job-conventions" "job"
  else
    deny_without_skill "superpowers-trainual:rails-job-conventions" "job"
  fi
  exit 0
fi

# Check if this is a database migration file
if [[ "$file_path" == */db/migrate/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-migration-conventions"; then
    allow_with_skill "superpowers-trainual:rails-migration-conventions" "migration"
  else
    deny_without_skill "superpowers-trainual:rails-migration-conventions" "migration"
  fi
  exit 0
fi

# Check if this is a spec file (Ruby)
if [[ "$file_path" == */spec/*.rb ]]; then
  if skill_loaded "superpowers-trainual:rails-testing-conventions"; then
    allow_with_skill "superpowers-trainual:rails-testing-conventions" "spec"
  else
    deny_without_skill "superpowers-trainual:rails-testing-conventions" "spec"
  fi
  exit 0
fi

# ============================================================
# Frontend conventions
# ============================================================

# Check if this is a React component file (.tsx)
if [[ "$file_path" == */react/components/*.tsx ]] && [[ "$file_path" != *.test.tsx ]] && [[ "$file_path" != *.stories.tsx ]]; then
  if skill_loaded "superpowers-trainual:react-component-conventions"; then
    allow_with_skill "superpowers-trainual:react-component-conventions" "React component"
  else
    deny_without_skill "superpowers-trainual:react-component-conventions" "React component"
  fi
  exit 0
fi

# Check if this is an RTK Query / Redux service file
if [[ "$file_path" == */redux/services/*.ts ]] || [[ "$file_path" == */redux/services/*.tsx ]]; then
  if skill_loaded "superpowers-trainual:rtk-query-conventions"; then
    allow_with_skill "superpowers-trainual:rtk-query-conventions" "RTK Query service"
  else
    deny_without_skill "superpowers-trainual:rtk-query-conventions" "RTK Query service"
  fi
  exit 0
fi

# Check if this is a Redux slice file
if [[ "$file_path" == */redux/domains/*Slice.ts ]]; then
  if skill_loaded "superpowers-trainual:rtk-query-conventions"; then
    allow_with_skill "superpowers-trainual:rtk-query-conventions" "Redux slice"
  else
    deny_without_skill "superpowers-trainual:rtk-query-conventions" "Redux slice"
  fi
  exit 0
fi

# Check if this is a TypeScript type definition or model file
if [[ "$file_path" == */react/types/*.ts ]] || [[ "$file_path" == */react/models/*.ts ]]; then
  if skill_loaded "superpowers-trainual:dto-transformer-conventions"; then
    allow_with_skill "superpowers-trainual:dto-transformer-conventions" "type definition"
  else
    deny_without_skill "superpowers-trainual:dto-transformer-conventions" "type definition"
  fi
  exit 0
fi

# Check if this is a frontend test file
if [[ "$file_path" == *.test.tsx ]] || [[ "$file_path" == *.test.ts ]]; then
  if skill_loaded "superpowers-trainual:frontend-testing-conventions"; then
    allow_with_skill "superpowers-trainual:frontend-testing-conventions" "frontend test"
  else
    deny_without_skill "superpowers-trainual:frontend-testing-conventions" "frontend test"
  fi
  exit 0
fi

# Check if this is a custom hook file
if [[ "$file_path" == */react/hooks/*.ts ]] || [[ "$file_path" == */react/hooks/*.tsx ]]; then
  if skill_loaded "superpowers-trainual:react-component-conventions"; then
    allow_with_skill "superpowers-trainual:react-component-conventions" "React hook"
  else
    deny_without_skill "superpowers-trainual:react-component-conventions" "React hook"
  fi
  exit 0
fi

# Check if this is a React context file
if [[ "$file_path" == */react/contexts/*.ts ]] || [[ "$file_path" == */react/contexts/*.tsx ]]; then
  if skill_loaded "superpowers-trainual:react-component-conventions"; then
    allow_with_skill "superpowers-trainual:react-component-conventions" "React context"
  else
    deny_without_skill "superpowers-trainual:react-component-conventions" "React context"
  fi
  exit 0
fi

# Check if this is a general TypeScript/TSX file in the react directory
if [[ "$file_path" == */react/*.ts ]] || [[ "$file_path" == */react/*.tsx ]]; then
  if skill_loaded "superpowers-trainual:typescript-conventions"; then
    allow_with_skill "superpowers-trainual:typescript-conventions" "TypeScript"
  else
    deny_without_skill "superpowers-trainual:typescript-conventions" "TypeScript"
  fi
  exit 0
fi

# For other files, proceed normally
log "BRANCH: No pattern matched -> allowing without skill requirement"
exit 0
