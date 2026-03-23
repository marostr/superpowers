#!/usr/bin/env bash
# Test hook enforcement: verify rails-conventions.sh blocks edits without skill loaded
# and allows edits after skill is loaded
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/../../hooks/rails-conventions.sh"

PASSED=0
FAILED=0

# Helper: run hook with given inputs, expect a specific exit code
test_hook() {
    local description="$1"
    local tool_name="$2"
    local file_path="$3"
    local transcript_path="$4"
    local expected_exit="$5"

    local input
    input=$(jq -n \
        --arg tool "$tool_name" \
        --arg path "$file_path" \
        --arg transcript "$transcript_path" \
        '{tool_name: $tool, tool_input: {file_path: $path}, transcript_path: $transcript}')

    local actual_exit=0
    echo "$input" | bash "$HOOK_SCRIPT" > /dev/null 2>&1 || actual_exit=$?

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "  [PASS] $description (exit $actual_exit)"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description (expected exit $expected_exit, got $actual_exit)"
        FAILED=$((FAILED + 1))
    fi
}

# Create a fake transcript that has skill loaded
TRANSCRIPT_WITH_SKILLS=$(mktemp)
cat > "$TRANSCRIPT_WITH_SKILLS" << 'EOF'
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-controller-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-model-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-interactor-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:jsonapi-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-policy-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-job-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-migration-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rails-testing-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:query-object-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:react-component-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:rtk-query-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:dto-transformer-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:frontend-testing-conventions"}}
{"type":"tool_use","name":"Skill","input":{"skill": "superpowers-trainual:typescript-conventions"}}
EOF

# Empty transcript (no skills loaded)
TRANSCRIPT_EMPTY=$(mktemp)
echo '{}' > "$TRANSCRIPT_EMPTY"

trap "rm -f $TRANSCRIPT_WITH_SKILLS $TRANSCRIPT_EMPTY" EXIT

echo "=== Hook Enforcement Tests ==="
echo ""

# ---- Rails Backend Tests ----
echo "--- Rails Backend: Block without skill ---"
test_hook "Block controller edit without skill" "Edit" "/app/controllers/api/goals_controller.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block model edit without skill" "Edit" "/app/models/operations/goal.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block interactor edit without skill" "Edit" "/app/interactors/operations/goals/create_goal.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block serializer edit without skill" "Edit" "/app/serializers/operations/goal_serializer.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block policy edit without skill" "Edit" "/app/policies/operations/goal_policy.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block query edit without skill" "Edit" "/app/queries/operations/goals_query.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block worker edit without skill" "Edit" "/app/workers/operations/sync_worker.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block job edit without skill" "Edit" "/app/jobs/process_job.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block migration edit without skill" "Edit" "/db/migrate/20240101_create_goals.rb" "$TRANSCRIPT_EMPTY" 2
test_hook "Block spec edit without skill" "Edit" "/spec/models/goal_spec.rb" "$TRANSCRIPT_EMPTY" 2

echo ""
echo "--- Rails Backend: Allow with skill loaded ---"
test_hook "Allow controller edit with skill" "Edit" "/app/controllers/api/goals_controller.rb" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow model edit with skill" "Edit" "/app/models/operations/goal.rb" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow interactor edit with skill" "Edit" "/app/interactors/operations/goals/create_goal.rb" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow serializer edit with skill" "Edit" "/app/serializers/operations/goal_serializer.rb" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow policy edit with skill" "Edit" "/app/policies/operations/goal_policy.rb" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow query edit with skill" "Edit" "/app/queries/operations/goals_query.rb" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow worker edit with skill" "Edit" "/app/workers/operations/sync_worker.rb" "$TRANSCRIPT_WITH_SKILLS" 0

echo ""

# ---- Frontend Tests ----
echo "--- Frontend: Block without skill ---"
test_hook "Block React component edit without skill" "Edit" "/app/javascript/react/components/application/goals/GoalCard.tsx" "$TRANSCRIPT_EMPTY" 2
test_hook "Block RTK service edit without skill" "Edit" "/app/javascript/react/redux/services/resourceApis/goals/goalsApi.ts" "$TRANSCRIPT_EMPTY" 2
test_hook "Block type definition edit without skill" "Edit" "/app/javascript/react/types/GoalTypes.ts" "$TRANSCRIPT_EMPTY" 2
test_hook "Block model type edit without skill" "Edit" "/app/javascript/react/models/Goal.ts" "$TRANSCRIPT_EMPTY" 2
test_hook "Block frontend test edit without skill" "Edit" "/app/javascript/react/components/application/goals/GoalCard.test.tsx" "$TRANSCRIPT_EMPTY" 2
test_hook "Block hook edit without skill" "Edit" "/app/javascript/react/hooks/useGoals.ts" "$TRANSCRIPT_EMPTY" 2
test_hook "Block context edit without skill" "Edit" "/app/javascript/react/contexts/GoalEditorContext.tsx" "$TRANSCRIPT_EMPTY" 2

echo ""
echo "--- Frontend: Allow with skill loaded ---"
test_hook "Allow React component edit with skill" "Edit" "/app/javascript/react/components/application/goals/GoalCard.tsx" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow RTK service edit with skill" "Edit" "/app/javascript/react/redux/services/resourceApis/goals/goalsApi.ts" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow type definition edit with skill" "Edit" "/app/javascript/react/types/GoalTypes.ts" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow frontend test edit with skill" "Edit" "/app/javascript/react/components/application/goals/GoalCard.test.tsx" "$TRANSCRIPT_WITH_SKILLS" 0
test_hook "Allow hook edit with skill" "Edit" "/app/javascript/react/hooks/useGoals.ts" "$TRANSCRIPT_WITH_SKILLS" 0

echo ""

# ---- Edge Cases ----
echo "--- Edge Cases ---"
test_hook "Allow non-convention file without skill" "Edit" "/README.md" "$TRANSCRIPT_EMPTY" 0
test_hook "Allow Skill tool always" "Skill" "" "$TRANSCRIPT_EMPTY" 0
test_hook "Allow when no file_path" "Edit" "" "$TRANSCRIPT_EMPTY" 0

echo ""
echo "=== Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "STATUS: FAILED"
    exit 1
else
    echo "STATUS: PASSED"
    exit 0
fi
