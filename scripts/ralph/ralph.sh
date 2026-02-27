#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--tool amp|claude|lemonade] [max_iterations]
#
# Tools:
#   amp       - Amplify (has file access)
#   claude    - Claude Code (has file access, cannot run nested)
#   lemonade  - Local LLM via Lemonade API (no file access, Ralph writes files)
#
# Adaptive parallelism:
#   - Starts with 1 task at a time
#   - If a task completes in < 5 min, next round sends 2 in parallel
#   - If any parallel task exceeds the threshold, reverts to 1 and logs a time report

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
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# Lemonade config
LEMONADE_URL="${LEMONADE_URL:-http://localhost:8000}"
LEMONADE_MODEL="${LEMONADE_MODEL:-Qwen3-Next-80B-A3B-Instruct-GGUF}"

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
  echo "iteration,subtask_id,prompt_file,start_time,end_time,duration_secs,parallel_slots,status" > "$TIMINGS_FILE"
fi

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

# Get N pending subtask prompt files
get_pending_prompts() {
  local count="$1"
  jq -r '.subtasks[] | select(.passes != true) | .promptFile' "$PRD_FILE" | head -"$count"
}

# Get subtask info by prompt file
get_subtask_id() {
  jq -r --arg pf "$1" '.subtasks[] | select(.promptFile == $pf) | .id' "$PRD_FILE"
}
get_subtask_title() {
  jq -r --arg pf "$1" '.subtasks[] | select(.promptFile == $pf) | .title' "$PRD_FILE"
}

# Run a single subtask
run_subtask() {
  local prompt_file="$1"
  local prompt_path="$SCRIPT_DIR/$prompt_file"
  local log_file="$2"  # Optional: redirect output to file for parallel runs
  local subtask_id
  subtask_id=$(get_subtask_id "$prompt_file")

  cd "$PROJECT_ROOT"

  if [[ "$TOOL" == "lemonade" ]]; then
    local prompt_content
    prompt_content=$(cat "$prompt_path")
    local response_file="$SCRIPT_DIR/.response-${subtask_id}.json"
    local output=""

    echo "  📡 Sending to Lemonade ($LEMONADE_MODEL)..."
    local response_text
    response_text=$(call_lemonade "$prompt_content" "$response_file")

    if [ -z "$response_text" ]; then
      output="Error: Empty response from Lemonade"
      echo "$output"
    else
      echo "  📝 Parsing response and writing files..."
      parse_and_write_files "$response_text"

      # Git add + commit + push (commit siempre, aunque falle validación)
      echo "  📦 Committing files..."
      git add -A
      if git diff --cached --quiet; then
        echo "  ℹ️  No changes to commit"
      else
        git commit -m "feat(#$(jq -r '.issueNumber' "$PRD_FILE")): subtask $subtask_id - $(get_subtask_title "$prompt_file")" || true
        git push -u origin "$CURRENT_BRANCH" || true
      fi

      # Run validation command from prompt (extract ```bash block under ## Validación)
      local validation_cmd
      validation_cmd=$(sed -n '/^## Validación/,/^## /{/^```bash/,/^```/{/^```/d;p}}' "$prompt_path" | head -5)
      if [ -n "$validation_cmd" ]; then
        echo "  🧪 Running validation: $validation_cmd"
        if eval "$validation_cmd" 2>&1; then
          echo "  ✅ Validation passed!"
          # Mark subtask as passed in prd.json
          local tmp
          tmp=$(jq --arg pf "$prompt_file" '(.subtasks[] | select(.promptFile == $pf)).passes = true' "$PRD_FILE")
          echo "$tmp" > "$PRD_FILE"
          output="VALIDATION_PASSED"
        else
          echo "  ❌ Validation failed — code committed anyway, will retry next iteration"
          output="VALIDATION_FAILED"
        fi
      else
        echo "  ⚠️  No validation command found, marking as passed"
        local tmp
        tmp=$(jq --arg pf "$prompt_file" '(.subtasks[] | select(.promptFile == $pf)).passes = true' "$PRD_FILE")
        echo "$tmp" > "$PRD_FILE"
        output="NO_VALIDATION"
      fi

      # Check if all done
      local remaining
      remaining=$(jq '[.subtasks[] | select(.passes != true)] | length' "$PRD_FILE")
      if [ "$remaining" -eq 0 ]; then
        output="<promise>COMPLETE</promise>"
      fi
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
  printf "%-5s %-8s %-20s %-10s %-8s %s\n" "ITER" "SUBTASK" "PROMPT" "DURACIÓN" "SLOTS" "ESTADO"
  printf "%-5s %-8s %-20s %-10s %-8s %s\n" "----" "-------" "--------------------" "---------" "------" "------"
  tail -n +2 "$TIMINGS_FILE" | while IFS=',' read -r iter sid pf start end dur slots status; do
    local mins=$((dur / 60))
    local secs=$((dur % 60))
    printf "%-5s %-8s %-20s %3dm %02ds   %-8s %s\n" "$iter" "$sid" "$pf" "$mins" "$secs" "$slots" "$status"
  done
  echo ""
  echo "Umbral paralelo: ${FAST_THRESHOLD}s ($(( FAST_THRESHOLD / 60 ))min)"
  echo "Slots actuales: $PARALLEL_SLOTS"
  echo "==============================================================="
}

ISSUE_TITLE=$(jq -r '.issueTitle // "unknown"' "$PRD_FILE")
echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo "Issue: $ISSUE_TITLE"
echo "Branch: $CURRENT_BRANCH"
if [[ "$TOOL" == "lemonade" ]]; then
  echo "Lemonade: $LEMONADE_URL (model: $LEMONADE_MODEL)"
fi
echo "Adaptive parallelism: starts at 1, scales to 2 if tasks < ${FAST_THRESHOLD}s"

i=0
while [ $i -lt $MAX_ITERATIONS ]; do
  i=$((i + 1))

  # Get pending subtasks (1 or 2 depending on PARALLEL_SLOTS)
  PENDING=$(get_pending_prompts "$PARALLEL_SLOTS")

  if [ -z "$PENDING" ]; then
    echo ""
    echo "All subtasks completed!"
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

    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL) [slots: $PARALLEL_SLOTS]"
    echo "  Subtask $SUBTASK_ID: $SUBTASK_TITLE"
    echo "  Prompt: $PROMPT_FILE"
    echo "==============================================================="

    START_TS=$(date +%s)
    START_TIME=$(date -Iseconds)
    OUTPUT=$(run_subtask "$PROMPT_FILE")
    END_TS=$(date +%s)
    END_TIME=$(date -Iseconds)
    DURATION=$((END_TS - START_TS))

    # Check completion
    STATUS="done"
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
      STATUS="COMPLETE"
    fi

    # Log timing
    echo "$i,$SUBTASK_ID,$PROMPT_FILE,$START_TIME,$END_TIME,$DURATION,$PARALLEL_SLOTS,$STATUS" >> "$TIMINGS_FILE"
    echo "[$i] Subtask $SUBTASK_ID ($PROMPT_FILE): ${DURATION}s [slots=$PARALLEL_SLOTS]" >> "$PROGRESS_FILE"

    if [ "$STATUS" = "COMPLETE" ]; then
      echo ""
      echo "Ralph completed all tasks!"
      print_time_report
      exit 0
    fi

    # Adaptive: decide next round's parallelism
    if [ "$DURATION" -lt "$FAST_THRESHOLD" ]; then
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

    # Check completion
    STATUS_1="done"; STATUS_2="done"
    grep -q "<promise>COMPLETE</promise>" "$LOG_1" 2>/dev/null && STATUS_1="COMPLETE"
    grep -q "<promise>COMPLETE</promise>" "$LOG_2" 2>/dev/null && STATUS_2="COMPLETE"

    # Log timings
    echo "$i,$SID_1,$PROMPT_1,$START_TIME,$END_TIME,$DUR_1,$PARALLEL_SLOTS,$STATUS_1" >> "$TIMINGS_FILE"
    echo "$i,$SID_2,$PROMPT_2,$START_TIME,$END_TIME,$DUR_2,$PARALLEL_SLOTS,$STATUS_2" >> "$TIMINGS_FILE"
    echo "[$i] Subtask $SID_1 ($PROMPT_1): ${DUR_1}s [parallel]" >> "$PROGRESS_FILE"
    echo "[$i] Subtask $SID_2 ($PROMPT_2): ${DUR_2}s [parallel]" >> "$PROGRESS_FILE"

    # Clean up logs
    rm -f "$LOG_1" "$LOG_2"

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
print_time_report
echo "Check $PROGRESS_FILE for status."
exit 1
