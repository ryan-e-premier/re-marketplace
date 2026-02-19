#!/bin/bash
#
# plan-view.sh — Show one plan section in a tmux popup with navigation keybinds
#
# Usage: plan-view.sh <plan-file> <section-idx>
# Outputs: next | prev | done | ask:<text> | change:<text>
#
# Configuration (env vars):
#   PLAN_VIEW_DELAY  — ms before keybindings activate (default: 1500)
#
# Requirements: tmux, neovim

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PLAN_FILE="${1:-}"
SECTION_IDX="${2:-1}"

# ── Validation ───────────────────────────────────────────────────────────────

if [[ -z "$PLAN_FILE" || ! -f "$PLAN_FILE" ]]; then
    echo "plan-view: plan file not found: ${PLAN_FILE:-<none>}" >&2
    exit 1
fi

PLAN_FILE="$(cd "$(dirname "$PLAN_FILE")" && pwd)/$(basename "$PLAN_FILE")"
PLAN_NAME="$(basename "$PLAN_FILE")"

# ── Dependency checks ────────────────────────────────────────────────────────

if [[ -z "${TMUX:-}" ]]; then
    echo "plan-view: not running inside tmux" >&2
    exit 1
fi

if ! command -v nvim &>/dev/null; then
    echo "plan-view: neovim is required but not found." >&2
    echo "  Install: brew install neovim (macOS) or apt install neovim (Linux)" >&2
    exit 1
fi

# ── Count sections (skipping ## inside code fences) ─────────────────────────

TOTAL_SECTIONS=$(awk '
    /^```/ { in_code = !in_code }
    !in_code && /^## / { count++ }
    END { print count+0 }
' "$PLAN_FILE")

if [[ "$TOTAL_SECTIONS" -eq 0 ]]; then
    echo "plan-view: no ## sections found in $PLAN_NAME" >&2
    exit 1
fi

# ── Extract the requested section ────────────────────────────────────────────

WORK_DIR="$(mktemp -d /tmp/plan-view-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

SIGNAL_FILE="$WORK_DIR/signal"
SECTION_FILE="$WORK_DIR/section.md"
VIM_SCRIPT="$WORK_DIR/plan.vim"

awk -v n="$SECTION_IDX" '
    /^```/ { in_code = !in_code }
    !in_code && /^## / {
        count++
        if (count == n)   { found=1; print; next }
        if (count > n && found) { exit }
    }
    found { print }
' "$PLAN_FILE" > "$SECTION_FILE"

if [[ ! -s "$SECTION_FILE" ]]; then
    echo "plan-view: could not extract section $SECTION_IDX" >&2
    exit 1
fi

SECTION_TITLE="$(head -1 "$SECTION_FILE" | sed 's/^## *//')"

# ── Configuration ────────────────────────────────────────────────────────────

ACTIVATION_DELAY="${PLAN_VIEW_DELAY:-1500}"

# ── Build vim config — two heredocs: ─────────────────────────────────────────
#   1. Unquoted: shell expands $SIGNAL_FILE, $SECTION_TITLE, $SECTION_IDX, etc.
#   2. Quoted:   pure vimscript (regexes, autocmd, no shell vars needed)

cat > "$VIM_SCRIPT" << VIMSCRIPT
" Plan Review — ${PLAN_NAME}
let g:signal_file = '${SIGNAL_FILE}'

function! PlanNext()
    call writefile(['next'], g:signal_file)
    sleep 100m
    qa!
endfunction

function! PlanPrev()
    call writefile(['prev'], g:signal_file)
    sleep 100m
    qa!
endfunction

function! PlanDone()
    call writefile(['done'], g:signal_file)
    sleep 100m
    qa!
endfunction

function! PlanAsk()
    call writefile(['ask'], g:signal_file)
    sleep 100m
    qa!
endfunction

function! PlanChange()
    call writefile(['change'], g:signal_file)
    sleep 100m
    qa!
endfunction

" Activation delay — prevents accidental keypresses when popup steals focus
let g:plan_keys_active = 0
let g:plan_activation_delay = ${ACTIVATION_DELAY}

function! PlanActivateKeys(timer)
    let g:plan_keys_active = 1
    nnoremap <buffer> <CR> :call PlanNext()<CR>
    nnoremap <buffer> n    :call PlanNext()<CR>
    nnoremap <buffer> p    :call PlanPrev()<CR>
    nnoremap <buffer> d    :call PlanDone()<CR>
    nnoremap <buffer> q    :call PlanAsk()<CR>
    nnoremap <buffer> e    :call PlanChange()<CR>
    redrawtabline
    redraw
endfunction

function! PlanGuardedNext()
    if !g:plan_keys_active
        echo "Keys locked — reading section..."
    else
        call PlanNext()
    endif
endfunction

" Bind keys immediately but guarded — activate after delay
nnoremap <buffer> <CR> :call PlanGuardedNext()<CR>
nnoremap <buffer> n    <Nop>
nnoremap <buffer> p    <Nop>
nnoremap <buffer> d    <Nop>
nnoremap <buffer> q    <Nop>
nnoremap <buffer> e    <Nop>

autocmd VimEnter * call timer_start(g:plan_activation_delay, 'PlanActivateKeys')

" Highlight groups — exact match with diff-review palette
highlight ClaudeHeader   guifg=#ffffff guibg=#7c3aed gui=bold   ctermbg=93 ctermfg=white  cterm=bold
highlight ClaudeFile     guifg=#e0e0e0 guibg=#7c3aed gui=NONE   ctermbg=93 ctermfg=255    cterm=NONE
highlight ClaudeApprove  guifg=#22c55e guibg=#7c3aed gui=bold   ctermbg=93 ctermfg=green  cterm=bold
highlight ClaudeFeedback guifg=#fbbf24 guibg=#7c3aed gui=bold   ctermbg=93 ctermfg=yellow cterm=bold
highlight ClaudeCancel   guifg=#f87171 guibg=#7c3aed gui=bold   ctermbg=93 ctermfg=red    cterm=bold
highlight ClaudeKey      guifg=#fef08a guibg=#7c3aed gui=bold   ctermbg=93 ctermfg=229    cterm=bold
highlight ClaudeExplain  guifg=#89b4fa guibg=#7c3aed gui=bold   ctermbg=93 ctermfg=117    cterm=bold

set showtabline=2

function! PlanTabline()
    let tl  = '%#ClaudeHeader# PLAN REVIEW %#ClaudeFile#│ ${SECTION_TITLE} %#ClaudeFile# §${SECTION_IDX}/${TOTAL_SECTIONS} %='
    if g:plan_keys_active
        let tl .= '%#ClaudeKey#Enter %#ClaudeApprove#✓next  '
        let tl .= '%#ClaudeKey#p %#ClaudeFeedback#↑prev  '
        let tl .= '%#ClaudeKey#q %#ClaudeExplain#?ask  '
        let tl .= '%#ClaudeKey#e %#ClaudeFeedback#✎change  '
        let tl .= '%#ClaudeKey#d %#ClaudeCancel#✗done '
    else
        let tl .= '%#ClaudeCancel# 🔒 Keys locked — reading section... '
    endif
    return tl
endfunction
set tabline=%!PlanTabline()
VIMSCRIPT

cat >> "$VIM_SCRIPT" << 'VIMSCRIPT'
autocmd VimEnter * call s:SetupView()
function! s:SetupView()
    setlocal filetype=markdown
    lua pcall(vim.treesitter.start)
    setlocal nomodifiable readonly
    setlocal wrap linebreak
    setlocal number cursorline
    setlocal scrolloff=5
    setlocal laststatus=0
    setlocal noshowmode noshowcmd noruler
    " Block accidental edits
    for s:k in split('i I a A o O s S R x X c C', ' ')
        execute 'nnoremap <buffer> <silent> ' . s:k . ' <Nop>'
    endfor
endfunction
VIMSCRIPT

# ── Open popup and wait for decision ────────────────────────────────────────

rm -f "$SIGNAL_FILE"

tmux display-popup -E -w 90% -h 90% \
    "nvim -nR '$SECTION_FILE' -S '$VIM_SCRIPT'" 2>/dev/null

# Poll for signal file (non-blocking popup returns here immediately)
wait_for_decision() {
    sleep 0.2
    local timeout=300
    local elapsed=0
    while [[ ! -f "$SIGNAL_FILE" ]]; do
        sleep 0.5
        elapsed=$((elapsed + 1))
        [[ $elapsed -ge $((timeout * 2)) ]] && echo "done" && return
    done
    cat "$SIGNAL_FILE"
}

decision=$(wait_for_decision)

# ── Handle ask / change — open feedback popup ────────────────────────────────

case "$decision" in
    ask)
        tmux display-popup -E -w 70% -h 20% \
            "bash '$SCRIPT_DIR/plan-feedback.sh' '$WORK_DIR/feedback.txt' 'What is your question?'" \
            2>/dev/null || true
        text=$(cat "$WORK_DIR/feedback.txt" 2>/dev/null || true)
        echo "ask:${text}"
        ;;
    change)
        tmux display-popup -E -w 70% -h 20% \
            "bash '$SCRIPT_DIR/plan-feedback.sh' '$WORK_DIR/feedback.txt' 'What would you like to change?'" \
            2>/dev/null || true
        text=$(cat "$WORK_DIR/feedback.txt" 2>/dev/null || true)
        echo "change:${text}"
        ;;
    *)
        echo "$decision"
        ;;
esac
