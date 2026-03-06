#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--tool amp|claude|lemonade] [max_iterations]
#
# Tools:
#   amp       - Amplify (has file access)
#   claude    - Claude Code (has file access, cannot run nested)
#   lemonade  - Local LLM via Lemonade API (no file access, Ralph writes files)
#
# Features:
#   - Auto-correction: retries failed tasks up to MAX_RETRIES with error context
#   - Codebase context: injects project tree into each prompt
#   - Dependencies: respects dependsOn field in prd.json
#   - State persistence: generates STATE.md after each iteration
#   - Adaptive parallelism: scales 1→2 slots if tasks are fast

set -e

# Parse arguments
TOOL="lemonade"  # Default to lemonade (local LLM)
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" && "$TOOL" != "lemonade" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp', 'claude' or 'lemonade'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
TIMINGS_FILE="$SCRIPT_DIR/timings.csv"
STATE_FILE="$SCRIPT_DIR/STATE.md"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# Lemonade config
LEMONADE_URL="${LEMONADE_URL:-http://localhost:8000}"
LEMONADE_MODEL="${LEMONADE_MODEL:-Qwen3-Next-80B-A3B-Instruct-GGUF}"

# Retry config
MAX_RETRIES=5

# Adaptive parallelism config
FAST_THRESHOLD=300  # 5 minutes in seconds
PARALLEL_SLOTS=1    # Start with 1, scale to 2 if fast

# Check prd.json exists
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: $PRD_FILE not found. Generate it first from a GitHub Issue."
  exit 1
fi

# Archive previous run if branch changed
if [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$TIMINGS_FILE" ] && cp "$TIMINGS_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$STATE_FILE" ] && cp "$STATE_FILE" "$ARCHIVE_FOLDER/"
    for f in "$SCRIPT_DIR"/prompt-*.md; do
      [ -f "$f" ] && cp "$f" "$ARCHIVE_FOLDER/"
    done
    echo "   Archived to: $ARCHIVE_FOLDER"

    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
if [ -n "$CURRENT_BRANCH" ]; then
  echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
fi

# Create branch if it doesn't exist
if [ -n "$CURRENT_BRANCH" ]; then
  cd "$PROJECT_ROOT"
  if ! git rev-parse --verify "$CURRENT_BRANCH" >/dev/null 2>&1; then
    echo "Creating branch: $CURRENT_BRANCH"
    git checkout -b "$CURRENT_BRANCH"
  else
    ACTIVE_BRANCH=$(git branch --show-current)
    if [ "$ACTIVE_BRANCH" != "$CURRENT_BRANCH" ]; then
      echo "Switching to branch: $CURRENT_BRANCH"
      git checkout "$CURRENT_BRANCH"
    fi
  fi
  cd "$SCRIPT_DIR"
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Initialize timings CSV if it doesn't exist
if [ ! -f "$TIMINGS_FILE" ]; then
  echo "iteration,subtask_id,prompt_file,start_time,end_time,duration_secs,parallel_slots,retries,status" > "$TIMINGS_FILE"
fi

# ─── Codebase context ──────────────────────────────────────────────────────

# Generate a project tree to inject into prompts (excludes noise)
get_codebase_context() {
  cd "$PROJECT_ROOT"
  echo "## Project Structure"
  echo '```'
  tree -L 3 -I 'node_modules|.git|target|build|dist|__pycache__|.cache|vendor' --dirsfirst 2>/dev/null || find . -maxdepth 3 -not -path '*/node_modules/*' -not -path '*/.git/*' | head -80
  echo '```'
  cd "$SCRIPT_DIR"
}

# Inject contents of existing files that the subtask will modify
# Reads the "files" array from prd.json for the given subtask
get_files_context() {
  local prompt_file="$1"
  local files
  files=$(jq -r --arg pf "$prompt_file" '.subtasks[] | select(.promptFile == $pf) | .files // [] | .[]' "$PRD_FILE" 2>/dev/null)

  if [ -z "$files" ]; then
    return
  fi

  echo ""
  echo "## Existing Files (read before modifying)"
  while IFS= read -r f; do
    if [ -f "$PROJECT_ROOT/$f" ]; then
      echo ""
      echo "### $f"
      echo '```'
      head -300 "$PROJECT_ROOT/$f"
      echo '```'
    fi
  done <<< "$files"
}

# ─── Lemonade helpers ───────────────────────────────────────────────────────

# System prompt that tells Lemonade how to format file output
LEMONADE_SYSTEM_PROMPT='You are a coding assistant. You receive a task and must produce the files requested.

CRITICAL OUTPUT FORMAT:
For each file you create or modify, output it in this exact format:

### FILE: path/to/file
```
file content here
```

Rules:
- The path after FILE: is relative to the project root
- Include the COMPLETE file content (not partial)
- Output ALL files needed to complete the task
- After all files, output a line: ### DONE
- Do NOT output explanations before the files. Go straight to ### FILE:
- If a task requires a command with sudo, output: ### NEEDS_SUDO: description of what is needed
- Do NOT use sudo yourself'

# Call Lemonade API and return the response text
call_lemonade() {
  local prompt_content="$1"
  local response_file="$2"

  # Build JSON payload with jq to handle escaping
  local payload
  payload=$(jq -n \
    --arg model "$LEMONADE_MODEL" \
    --arg system "$LEMONADE_SYSTEM_PROMPT" \
    --arg user "$prompt_content" \
    '{
      model: $model,
      messages: [
        { role: "system", content: $system },
        { role: "user", content: $user }
      ],
      temperature: 0.2,
      max_tokens: 16384,
      stream: false
    }')

  # Call API
  local http_code
  http_code=$(curl -s -w "%{http_code}" -o "$response_file" \
    -X POST "$LEMONADE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    --max-time 600)

  if [ "$http_code" != "200" ]; then
    echo "Error: Lemonade API returned HTTP $http_code"
    cat "$response_file" 2>/dev/null
    return 1
  fi

  # Extract content from OpenAI-compatible response
  jq -r '.choices[0].message.content // empty' "$response_file"
}

# Parse Lemonade response and write files to disk
parse_and_write_files() {
  local response_text="$1"
  local files_written=0

  # Extract file blocks: ### FILE: path\n```\ncontent\n```
  local current_file=""
  local in_code_block=false
  local content=""

  while IFS= read -r line; do
    # Detect ### FILE: path
    if [[ "$line" =~ ^###\ FILE:\ (.+)$ ]]; then
      # Write previous file if exists
      if [ -n "$current_file" ] && [ -n "$content" ]; then
        local dir
        dir=$(dirname "$PROJECT_ROOT/$current_file")
        mkdir -p "$dir"
        # Remove trailing newline
        printf '%s' "$content" > "$PROJECT_ROOT/$current_file"
        echo "  ✏️  Wrote: $current_file"
        files_written=$((files_written + 1))
      fi
      current_file="${BASH_REMATCH[1]}"
      # Trim whitespace
      current_file=$(echo "$current_file" | xargs)
      content=""
      in_code_block=false
      continue
    fi

    # Detect ### NEEDS_SUDO:
    if [[ "$line" =~ ^###\ NEEDS_SUDO:\ (.+)$ ]]; then
      local sudo_desc="${BASH_REMATCH[1]}"
      echo "  ⚠️  NEEDS SUDO: $sudo_desc"
      # Create GitHub issue for sudo requirement
      cd "$PROJECT_ROOT"
      gh issue create --title "Instalar: $sudo_desc" --body "Ralph detectó que se necesita sudo para: $sudo_desc" 2>/dev/null || true
      cd "$SCRIPT_DIR"
      continue
    fi

    # Detect ### DONE
    if [[ "$line" == "### DONE" ]]; then
      # Write last file
      if [ -n "$current_file" ] && [ -n "$content" ]; then
        local dir
        dir=$(dirname "$PROJECT_ROOT/$current_file")
        mkdir -p "$dir"
        printf '%s' "$content" > "$PROJECT_ROOT/$current_file"
        echo "  ✏️  Wrote: $current_file"
        files_written=$((files_written + 1))
      fi
      break
    fi

    # Handle code block markers
    if [ -n "$current_file" ]; then
      if [[ "$line" =~ ^\`\`\` ]] && [ "$in_code_block" = false ]; then
        in_code_block=true
        continue
      fi
      if [[ "$line" == '```' ]] && [ "$in_code_block" = true ]; then
        in_code_block=false
        continue
      fi
      if [ "$in_code_block" = true ]; then
        if [ -n "$content" ]; then
          content="$content
$line"
        else
          content="$line"
        fi
      fi
    fi
  done <<< "$response_text"

  # Handle case where ### DONE was not found but there's a pending file
  if [ -n "$current_file" ] && [ -n "$content" ] && [ "$files_written" -eq 0 ] || \
     [ -n "$current_file" ] && [ -n "$content" ] && [ "$in_code_block" = true ]; then
    local dir
    dir=$(dirname "$PROJECT_ROOT/$current_file")
    mkdir -p "$dir"
    printf '%s' "$content" > "$PROJECT_ROOT/$current_file"
    echo "  ✏️  Wrote: $current_file"
    files_written=$((files_written + 1))
  fi

  echo "  📁 Total files written: $files_written"
  return 0
}

# ─── End Lemonade helpers ───────────────────────────────────────────────────

# ─── Dependency helpers ─────────────────────────────────────────────────────

# Check if all dependencies of a subtask have passed
deps_satisfied() {
  local prompt_file="$1"
  local deps
  deps=$(jq -r --arg pf "$prompt_file" '.subtasks[] | select(.promptFile == $pf) | .dependsOn // [] | .[]' "$PRD_FILE" 2>/dev/null)

  if [ -z "$deps" ]; then
    return 0  # No dependencies
  fi

  while IFS= read -r dep_id; do
    local dep_passed
    dep_passed=$(jq -r --argjson id "$dep_id" '.subtasks[] | select(.id == $id) | .passes // false' "$PRD_FILE")
    if [ "$dep_passed" != "true" ]; then
      return 1  # Dependency not met
    fi
  done <<< "$deps"

  return 0  # All dependencies met
}

# Get N pending subtask prompt files (respecting dependencies)
get_pending_prompts() {
  local count="$1"
  local pending
  pending=$(jq -r '.subtasks[] | select(.passes != true) | .promptFile' "$PRD_FILE")

  if [ -z "$pending" ]; then
    return
  fi

  local ready_count=0
  while IFS= read -r pf; do
    if deps_satisfied "$pf"; then
      echo "$pf"
      ready_count=$((ready_count + 1))
      if [ "$ready_count" -ge "$count" ]; then
        break
      fi
    fi
  done <<< "$pending"
}

# ─── End Dependency helpers ─────────────────────────────────────────────────

# Get subtask info by prompt file
get_subtask_id() {
  jq -r --arg pf "$1" '.subtasks[] | select(.promptFile == $pf) | .id' "$PRD_FILE"
}
get_subtask_title() {
  jq -r --arg pf "$1" '.subtasks[] | select(.promptFile == $pf) | .title' "$PRD_FILE"
}
get_subtask_retries() {
  jq -r --arg pf "$1" '.subtasks[] | select(.promptFile == $pf) | .retries // 0' "$PRD_FILE"
}

# Get verification command: first from prd.json "verify" field, then from prompt ## Validación block
get_verify_cmd() {
  local prompt_file="$1"
  local prompt_path="$SCRIPT_DIR/$prompt_file"

  # Try prd.json verify field first
  local verify_from_prd
  verify_from_prd=$(jq -r --arg pf "$prompt_file" '.subtasks[] | select(.promptFile == $pf) | .verify // empty' "$PRD_FILE")
  if [ -n "$verify_from_prd" ]; then
    echo "$verify_from_prd"
    return
  fi

  # Fallback: extract from prompt markdown
  sed -n '/^## Validación/,/^## /{/^```bash/,/^```/{/^```/d;p}}' "$prompt_path" | head -5
}

# Build retry prompt with error context and affected files
build_retry_prompt() {
  local original_prompt="$1"
  local error_output="$2"
  local retry_num="$3"
  local prompt_file="$4"

  # Collect the files this subtask generated/modified
  local affected_files=""
  local files_field
  files_field=$(jq -r --arg pf "$prompt_file" '.subtasks[] | select(.promptFile == $pf) | .files // [] | .[]' "$PRD_FILE" 2>/dev/null)

  if [ -n "$files_field" ]; then
    while IFS= read -r f; do
      if [ -f "$PROJECT_ROOT/$f" ]; then
        affected_files="${affected_files}
### FILE (current): $f
\`\`\`
$(cat "$PROJECT_ROOT/$f" 2>/dev/null | head -200)
\`\`\`"
      fi
    done <<< "$files_field"
  fi

  cat <<RETRY_EOF
# RETRY $retry_num/$MAX_RETRIES — Fix the errors below

## Original task
$original_prompt

## Current files (your previous output)
$affected_files

## Validation error
\`\`\`
$error_output
\`\`\`

## Instructions
- Fix ONLY the errors shown above
- Output ALL files again with the corrections (complete content, not patches)
- Use the same ### FILE: format
RETRY_EOF
}

# ─── STATE.md generation ───────────────────────────────────────────────────

generate_state() {
  local issue_title
  issue_title=$(jq -r '.issueTitle // "unknown"' "$PRD_FILE")
  local issue_number
  issue_number=$(jq -r '.issueNumber // "?"' "$PRD_FILE")

  cat > "$STATE_FILE" <<STATE_EOF
# Ralph State — Issue #${issue_number}: ${issue_title}

**Branch:** ${CURRENT_BRANCH}
**Updated:** $(date -Iseconds)
**Tool:** ${TOOL}

## Subtasks

| ID | Title | Status | Retries |
|---|---|---|---|
STATE_EOF

  jq -r '.subtasks[] | "| \(.id) | \(.title) | \(if .passes then "PASS" else "PENDING" end) | \(.retries // 0) |"' "$PRD_FILE" >> "$STATE_FILE"

  local total passed pending
  total=$(jq '.subtasks | length' "$PRD_FILE")
  passed=$(jq '[.subtasks[] | select(.passes == true)] | length' "$PRD_FILE")
  pending=$((total - passed))

  cat >> "$STATE_FILE" <<STATE_EOF

## Summary

- **Total:** ${total} subtasks
- **Passed:** ${passed}
- **Pending:** ${pending}

## How to resume

\`\`\`bash
cd $(dirname "$SCRIPT_DIR")
./scripts/ralph/ralph.sh --tool ${TOOL}
\`\`\`
STATE_EOF
}

# ─── End STATE.md generation ───────────────────────────────────────────────

# Run a single subtask (with retry loop for lemonade)
run_subtask() {
  local prompt_file="$1"
  local prompt_path="$SCRIPT_DIR/$prompt_file"
  local log_file="$2"  # Optional: redirect output to file for parallel runs
  local subtask_id
  subtask_id=$(get_subtask_id "$prompt_file")

  cd "$PROJECT_ROOT"

  if [[ "$TOOL" == "lemonade" ]]; then
    local original_prompt
    original_prompt=$(cat "$prompt_path")
    local response_file="$SCRIPT_DIR/.response-${subtask_id}.json"
    local output=""
    local retries
    retries=$(get_subtask_retries "$prompt_file")

    # Inject codebase context + existing file contents into the prompt
    local codebase_ctx
    codebase_ctx=$(get_codebase_context)
    local files_ctx
    files_ctx=$(get_files_context "$prompt_file")
    local full_prompt="${codebase_ctx}
${files_ctx}

${original_prompt}"

    local current_prompt="$full_prompt"
    local attempt=0
    local task_passed=false

    while [ "$attempt" -le "$MAX_RETRIES" ] && [ "$task_passed" = false ]; do
      if [ "$attempt" -gt 0 ]; then
        echo "  🔄 Retry $attempt/$MAX_RETRIES for subtask $subtask_id"
      fi

      echo "  📡 Sending to Lemonade ($LEMONADE_MODEL)..."
      local response_text
      response_text=$(call_lemonade "$current_prompt" "$response_file")

      echo "  📡 Response length: ${#response_text} chars"
      if [ -z "$response_text" ]; then
        echo "  ❌ Empty response from Lemonade"
        attempt=$((attempt + 1))
        retries=$((retries + 1))
        # Update retries in prd.json
        local tmp
        tmp=$(jq --arg pf "$prompt_file" --argjson r "$retries" '(.subtasks[] | select(.promptFile == $pf)).retries = $r' "$PRD_FILE")
        echo "$tmp" > "$PRD_FILE"
        sleep 3
        continue
      fi

      echo "  📝 Parsing response and writing files..."
      parse_and_write_files "$response_text"

      # Git add + commit + push
      echo "  📦 Committing files..."
      git add -A
      if git diff --cached --quiet; then
        echo "  ℹ️  No changes to commit"
      else
        local commit_suffix=""
        if [ "$attempt" -gt 0 ]; then
          commit_suffix=" (retry $attempt)"
        fi
        git commit -m "feat(#$(jq -r '.issueNumber' "$PRD_FILE")): subtask $subtask_id - $(get_subtask_title "$prompt_file")${commit_suffix}" || true
        git push -u origin "$CURRENT_BRANCH" || true
      fi

      # Run validation
      local validation_cmd
      validation_cmd=$(get_verify_cmd "$prompt_file")
      if [ -n "$validation_cmd" ]; then
        echo "  🧪 Running validation: $validation_cmd"
        local validation_output
        validation_output=$(eval "$validation_cmd" 2>&1) && validation_exit=0 || validation_exit=$?

        if [ "$validation_exit" -eq 0 ]; then
          echo "  ✅ Validation passed!"
          task_passed=true
          output="VALIDATION_PASSED"
        else
          echo "  ❌ Validation failed (attempt $((attempt + 1))/$((MAX_RETRIES + 1)))"
          echo "  Error: $validation_output"
          attempt=$((attempt + 1))
          retries=$((retries + 1))

          # Update retries in prd.json
          local tmp
          tmp=$(jq --arg pf "$prompt_file" --argjson r "$retries" '(.subtasks[] | select(.promptFile == $pf)).retries = $r' "$PRD_FILE")
          echo "$tmp" > "$PRD_FILE"

          if [ "$attempt" -le "$MAX_RETRIES" ]; then
            # Build retry prompt with error context
            current_prompt=$(build_retry_prompt "$original_prompt" "$validation_output" "$attempt" "$prompt_file")
            # Re-inject codebase context
            current_prompt="${codebase_ctx}

${current_prompt}"
          else
            echo "  💀 Max retries ($MAX_RETRIES) reached for subtask $subtask_id — moving on"
            output="MAX_RETRIES_REACHED"
            # Mark as failed explicitly
            local tmp
            tmp=$(jq --arg pf "$prompt_file" '(.subtasks[] | select(.promptFile == $pf)).failed = true' "$PRD_FILE")
            echo "$tmp" > "$PRD_FILE"
          fi
        fi
      else
        echo "  ⚠️  No validation command found, marking as passed"
        task_passed=true
        output="NO_VALIDATION"
      fi
    done

    # Mark as passed if validation succeeded
    if [ "$task_passed" = true ]; then
      local tmp
      tmp=$(jq --arg pf "$prompt_file" '(.subtasks[] | select(.promptFile == $pf)).passes = true' "$PRD_FILE")
      echo "$tmp" > "$PRD_FILE"
    fi

    # Check if all done
    local remaining
    remaining=$(jq '[.subtasks[] | select(.passes != true)] | length' "$PRD_FILE")
    if [ "$remaining" -eq 0 ]; then
      output="<promise>COMPLETE</promise>"
    fi

    rm -f "$response_file"

    if [ -n "$log_file" ]; then
      echo "$output" > "$log_file"
    else
      echo "$output"
    fi

  elif [[ "$TOOL" == "amp" ]]; then
    if [ -n "$log_file" ]; then
      cat "$prompt_path" | amp --dangerously-allow-all >"$log_file" 2>&1 || true
    else
      cat "$prompt_path" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr || true
    fi

  else
    # claude
    if [ -n "$log_file" ]; then
      claude --dangerously-skip-permissions --print < "$prompt_path" >"$log_file" 2>&1 || true
    else
      claude --dangerously-skip-permissions --print < "$prompt_path" 2>&1 | tee /dev/stderr || true
    fi
  fi

  cd "$SCRIPT_DIR"
}

# Print time report
print_time_report() {
  echo ""
  echo "==============================================================="
  echo "  INFORME DE TIEMPOS"
  echo "==============================================================="
  echo ""
  printf "%-5s %-8s %-20s %-10s %-8s %-8s %s\n" "ITER" "SUBTASK" "PROMPT" "DURACIÓN" "SLOTS" "RETRIES" "ESTADO"
  printf "%-5s %-8s %-20s %-10s %-8s %-8s %s\n" "----" "-------" "--------------------" "---------" "------" "-------" "------"
  tail -n +2 "$TIMINGS_FILE" | while IFS=',' read -r iter sid pf start end dur slots retries status; do
    local mins=$((dur / 60))
    local secs=$((dur % 60))
    printf "%-5s %-8s %-20s %3dm %02ds   %-8s %-8s %s\n" "$iter" "$sid" "$pf" "$mins" "$secs" "$slots" "$retries" "$status"
  done
  echo ""
  echo "Umbral paralelo: ${FAST_THRESHOLD}s ($(( FAST_THRESHOLD / 60 ))min)"
  echo "Slots actuales: $PARALLEL_SLOTS"
  echo "Max retries: $MAX_RETRIES"
  echo "==============================================================="
}

ISSUE_TITLE=$(jq -r '.issueTitle // "unknown"' "$PRD_FILE")
echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo "Issue: $ISSUE_TITLE"
echo "Branch: $CURRENT_BRANCH"
if [[ "$TOOL" == "lemonade" ]]; then
  echo "Lemonade: $LEMONADE_URL (model: $LEMONADE_MODEL)"
fi
echo "Auto-correction: up to $MAX_RETRIES retries per subtask"
echo "Adaptive parallelism: starts at 1, scales to 2 if tasks < ${FAST_THRESHOLD}s"

# Check for blocked subtasks (unmet dependencies with no ready tasks)
BLOCKED_CHECK=$(get_pending_prompts 1)
if [ -z "$BLOCKED_CHECK" ]; then
  PENDING_COUNT=$(jq '[.subtasks[] | select(.passes != true)] | length' "$PRD_FILE")
  if [ "$PENDING_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  $PENDING_COUNT subtasks pending but ALL are blocked by unmet dependencies or marked as failed."
    echo "Check prd.json for dependsOn fields and failed tasks."
    jq -r '.subtasks[] | select(.passes != true) | "  - Subtask \(.id): \(.title) (dependsOn: \(.dependsOn // [] | join(", ")))\(if .failed then " [FAILED]" else "" end)"' "$PRD_FILE"
    exit 1
  fi
fi

i=0
while [ $i -lt $MAX_ITERATIONS ]; do
  i=$((i + 1))

  # Get pending subtasks (1 or 2 depending on PARALLEL_SLOTS), respecting dependencies
  PENDING=$(get_pending_prompts "$PARALLEL_SLOTS")

  if [ -z "$PENDING" ]; then
    # Check if there are blocked tasks remaining
    PENDING_COUNT=$(jq '[.subtasks[] | select(.passes != true)] | length' "$PRD_FILE")
    if [ "$PENDING_COUNT" -gt 0 ]; then
      echo ""
      echo "⚠️  No ready subtasks — $PENDING_COUNT blocked by dependencies or failed."
      jq -r '.subtasks[] | select(.passes != true) | "  - Subtask \(.id): \(.title)\(if .failed then " [FAILED]" else " [BLOCKED]" end)"' "$PRD_FILE"
      generate_state
      print_time_report
      exit 1
    fi
    echo ""
    echo "All subtasks completed!"
    generate_state
    print_time_report
    echo "<promise>COMPLETE</promise>"
    exit 0
  fi

  TASK_COUNT=$(echo "$PENDING" | wc -l)

  if [ "$TASK_COUNT" -eq 1 ] || [ "$PARALLEL_SLOTS" -eq 1 ]; then
    # === SEQUENTIAL: 1 task ===
    PROMPT_FILE=$(echo "$PENDING" | head -1)
    SUBTASK_ID=$(get_subtask_id "$PROMPT_FILE")
    SUBTASK_TITLE=$(get_subtask_title "$PROMPT_FILE")
    SUBTASK_RETRIES=$(get_subtask_retries "$PROMPT_FILE")

    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL) [slots: $PARALLEL_SLOTS]"
    echo "  Subtask $SUBTASK_ID: $SUBTASK_TITLE"
    echo "  Prompt: $PROMPT_FILE (retries so far: $SUBTASK_RETRIES)"
    echo "==============================================================="

    START_TS=$(date +%s)
    START_TIME=$(date -Iseconds)
    LOG_SEQ="$SCRIPT_DIR/.output-seq-${SUBTASK_ID}.log"
    run_subtask "$PROMPT_FILE" "$LOG_SEQ"
    END_TS=$(date +%s)
    END_TIME=$(date -Iseconds)
    DURATION=$((END_TS - START_TS))
    OUTPUT=$(cat "$LOG_SEQ" 2>/dev/null || echo "")
    cat "$LOG_SEQ" 2>/dev/null || true
    rm -f "$LOG_SEQ"

    # Get final retry count
    FINAL_RETRIES=$(get_subtask_retries "$PROMPT_FILE")

    # Check completion
    STATUS="done"
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
      STATUS="COMPLETE"
    elif echo "$OUTPUT" | grep -q "MAX_RETRIES_REACHED"; then
      STATUS="FAILED"
    fi

    # Log timing
    echo "$i,$SUBTASK_ID,$PROMPT_FILE,$START_TIME,$END_TIME,$DURATION,$PARALLEL_SLOTS,$FINAL_RETRIES,$STATUS" >> "$TIMINGS_FILE"
    echo "[$i] Subtask $SUBTASK_ID ($PROMPT_FILE): ${DURATION}s retries=$FINAL_RETRIES [slots=$PARALLEL_SLOTS] $STATUS" >> "$PROGRESS_FILE"

    # Generate state after each iteration
    generate_state

    if [ "$STATUS" = "COMPLETE" ]; then
      echo ""
      echo "Ralph completed all tasks!"
      print_time_report
      exit 0
    fi

    # Adaptive: decide next round's parallelism
    # Lemonade (local LLM) cannot handle concurrent requests — always sequential
    if [ "$TOOL" == "lemonade" ]; then
      PARALLEL_SLOTS=1
    elif [ "$DURATION" -lt "$FAST_THRESHOLD" ]; then
      if [ "$PARALLEL_SLOTS" -eq 1 ]; then
        PARALLEL_SLOTS=2
        echo "  ⚡ Task finished in ${DURATION}s (< ${FAST_THRESHOLD}s) → scaling to 2 parallel slots"
      fi
    else
      if [ "$PARALLEL_SLOTS" -gt 1 ]; then
        PARALLEL_SLOTS=1
        echo "  🐢 Task took ${DURATION}s (>= ${FAST_THRESHOLD}s) → reverting to 1 slot"
        print_time_report
      fi
    fi

  else
    # === PARALLEL: 2 tasks ===
    PROMPT_1=$(echo "$PENDING" | sed -n '1p')
    PROMPT_2=$(echo "$PENDING" | sed -n '2p')
    SID_1=$(get_subtask_id "$PROMPT_1")
    SID_2=$(get_subtask_id "$PROMPT_2")
    TITLE_1=$(get_subtask_title "$PROMPT_1")
    TITLE_2=$(get_subtask_title "$PROMPT_2")

    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL) [PARALLEL: 2 slots]"
    echo "  Subtask $SID_1: $TITLE_1"
    echo "  Subtask $SID_2: $TITLE_2"
    echo "==============================================================="

    LOG_1="$SCRIPT_DIR/.output-${SID_1}.log"
    LOG_2="$SCRIPT_DIR/.output-${SID_2}.log"
    START_TS=$(date +%s)
    START_TIME=$(date -Iseconds)

    # Launch both in background
    run_subtask "$PROMPT_1" "$LOG_1" &
    PID_1=$!
    run_subtask "$PROMPT_2" "$LOG_2" &
    PID_2=$!

    # Wait for both
    FAIL_1=0; FAIL_2=0
    wait $PID_1 || FAIL_1=1
    TS_1=$(date +%s)
    DUR_1=$((TS_1 - START_TS))

    wait $PID_2 || FAIL_2=1
    TS_2=$(date +%s)
    DUR_2=$((TS_2 - START_TS))

    END_TIME=$(date -Iseconds)
    MAX_DUR=$((DUR_1 > DUR_2 ? DUR_1 : DUR_2))

    # Show outputs
    echo "--- Output subtask $SID_1 ($PROMPT_1) [${DUR_1}s] ---"
    cat "$LOG_1" 2>/dev/null || true
    echo "--- Output subtask $SID_2 ($PROMPT_2) [${DUR_2}s] ---"
    cat "$LOG_2" 2>/dev/null || true

    # Get retry counts
    RETRIES_1=$(get_subtask_retries "$PROMPT_1")
    RETRIES_2=$(get_subtask_retries "$PROMPT_2")

    # Check completion
    STATUS_1="done"; STATUS_2="done"
    grep -q "<promise>COMPLETE</promise>" "$LOG_1" 2>/dev/null && STATUS_1="COMPLETE"
    grep -q "<promise>COMPLETE</promise>" "$LOG_2" 2>/dev/null && STATUS_2="COMPLETE"
    grep -q "MAX_RETRIES_REACHED" "$LOG_1" 2>/dev/null && STATUS_1="FAILED"
    grep -q "MAX_RETRIES_REACHED" "$LOG_2" 2>/dev/null && STATUS_2="FAILED"

    # Log timings
    echo "$i,$SID_1,$PROMPT_1,$START_TIME,$END_TIME,$DUR_1,$PARALLEL_SLOTS,$RETRIES_1,$STATUS_1" >> "$TIMINGS_FILE"
    echo "$i,$SID_2,$PROMPT_2,$START_TIME,$END_TIME,$DUR_2,$PARALLEL_SLOTS,$RETRIES_2,$STATUS_2" >> "$TIMINGS_FILE"
    echo "[$i] Subtask $SID_1 ($PROMPT_1): ${DUR_1}s retries=$RETRIES_1 [parallel] $STATUS_1" >> "$PROGRESS_FILE"
    echo "[$i] Subtask $SID_2 ($PROMPT_2): ${DUR_2}s retries=$RETRIES_2 [parallel] $STATUS_2" >> "$PROGRESS_FILE"

    # Clean up logs
    rm -f "$LOG_1" "$LOG_2"

    # Generate state after each iteration
    generate_state

    if [ "$STATUS_1" = "COMPLETE" ] || [ "$STATUS_2" = "COMPLETE" ]; then
      echo ""
      echo "Ralph completed all tasks!"
      print_time_report
      exit 0
    fi

    # Adaptive: if either task was slow, revert to 1
    if [ "$MAX_DUR" -ge "$FAST_THRESHOLD" ]; then
      PARALLEL_SLOTS=1
      echo "  🐢 Parallel run took ${MAX_DUR}s (>= ${FAST_THRESHOLD}s) → reverting to 1 slot"
      print_time_report
    else
      echo "  ⚡ Parallel run: ${DUR_1}s + ${DUR_2}s (max ${MAX_DUR}s < ${FAST_THRESHOLD}s) → keeping 2 slots"
    fi
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
generate_state
print_time_report
echo "Check $PROGRESS_FILE and $STATE_FILE for status."
exit 1
