#!/bin/bash
#
# Claude Code Status Line — Mono Minimal
# One gray. Only what matters. Nothing else.
#
# Requirements: jq, Nerd Font
#

# ─────────────────────────────────────────────────────────────────────────────
# Palette — single tone
# ─────────────────────────────────────────────────────────────────────────────

RST=$'\033[0m'
C=$'\033[38;5;243m'    # one gray to rule them all
DIM=$'\033[38;5;238m'  # faded — bar empty blocks only

# ─────────────────────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────────────────────

INPUT=$(cat)

MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "?"')
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // "."')
DIR=$(basename "$CWD")

CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
TOTAL_IN=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0')
TOTAL_OUT=$(echo "$INPUT" | jq -r '.context_window.total_output_tokens // 0')

COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

fmt_k() {
    local n=$1
    [[ $n -ge 1000000 ]] && { awk "BEGIN {printf \"%.1fM\", $n/1000000}"; return; }
    [[ $n -ge 1000 ]]    && { awk "BEGIN {printf \"%.0fk\", $n/1000}"; return; }
    echo "$n"
}

fmt_time() {
    local s=$(($1/1000)) m h
    m=$((s/60)); h=$((m/60)); m=$((m%60))
    [[ $h -gt 0 ]] && echo "${h}h${m}m" || echo "${m}m"
}

# ─────────────────────────────────────────────────────────────────────────────
# Build
# ─────────────────────────────────────────────────────────────────────────────

main() {
    local out=""
    local s="  "  # consistent double-space separator

    # dir
    out+="${C} ${DIR}"

    # git
    if git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
        local branch dirty=""
        branch=$(git -C "$CWD" --no-optional-locks branch --show-current 2>/dev/null)
        [[ -z "$branch" ]] && branch="detached"
        if ! git -C "$CWD" --no-optional-locks diff --quiet 2>/dev/null ||
           ! git -C "$CWD" --no-optional-locks diff --cached --quiet 2>/dev/null ||
           [[ -n $(git -C "$CWD" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | head -1) ]]; then
            dirty=" ●"
        fi
        out+="${s} ${branch}${dirty}"
    fi

    # model
    out+="${s}${MODEL}"

    # cost
    local cost_fmt
    cost_fmt=$(awk "BEGIN {printf \"%.2f\", $COST}")
    out+="${s}\$${cost_fmt}"

    # tokens in/out
    out+="${s}$(fmt_k "$TOTAL_IN")/$(fmt_k "$TOTAL_OUT")"

    # context bar
    local pct=${CTX_PCT%.*}
    pct=${pct:-0}
    local filled empty bar=""
    filled=$(awk "BEGIN {printf \"%.0f\", ($pct/100)*10}")
    filled=${filled:-0}
    empty=$((10 - filled))
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${DIM}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    out+="${s}${C}${bar}${C} ${pct}%"

    # duration
    [[ "$DURATION_MS" != "0" ]] && out+="${s} $(fmt_time "$DURATION_MS")"

    printf "%b%b" "$out" "$RST"
}

main
