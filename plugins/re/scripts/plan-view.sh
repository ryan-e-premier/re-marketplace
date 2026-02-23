#!/bin/bash
#
# plan-view.sh — Show a plan section in a tmux popup with navigation
#
# Usage:  plan-view.sh <plan_file> <section_num> <editor> <total_sections>
# Output: next | prev | done | ask:<text> | change:<text>
#
# Supported editors: nvim, vim, nano
# Requires: tmux
#

set -uo pipefail

PLAN_FILE="$1"
SECTION_NUM="${2:-1}"
EDITOR_CMD="${3:-nvim}"
TOTAL="${4:-1}"

TEMP_DIR=$(mktemp -d /tmp/plan-review.XXXXXX)
SECTION_FILE="$TEMP_DIR/section.md"
SIGNAL_FILE="$TEMP_DIR/signal"

# ── Extract section N ─────────────────────────────────────────────

awk -v target="$SECTION_NUM" '
    /^```/ { in_code = !in_code }
    !in_code && /^## / {
        n++
        if (n > target) { exit }
        capturing = (n == target)
    }
    capturing { print }
' "$PLAN_FILE" > "$SECTION_FILE"

# ── Vim/Neovim popup with keybindings ────────────────────────────

open_vim_popup() {
    local vim_script="$TEMP_DIR/plan-review.vim"

    cat > "$vim_script" << VIMSCRIPT
" Plan Review  ·  Section ${SECTION_NUM} of ${TOTAL}
let g:signal_file = '${SIGNAL_FILE}'

function! WriteSignal(val)
    call writefile([a:val], g:signal_file)
    sleep 50m
    qa!
endfunction

function! AskQuestion()
    let q = input('Question: ')
    if q != ''
        call WriteSignal('ask:' . q)
    endif
endfunction

function! RequestChange()
    let c = input('Describe change: ')
    if c != ''
        call WriteSignal('change:' . c)
    endif
endfunction

nnoremap <buffer> <CR>  :call WriteSignal('next')<CR>
nnoremap <buffer> n     :call WriteSignal('next')<CR>
nnoremap <buffer> p     :call WriteSignal('prev')<CR>
nnoremap <buffer> d     :call WriteSignal('done')<CR>
nnoremap <buffer> q     :call AskQuestion()<CR>
nnoremap <buffer> e     :call RequestChange()<CR>

set noruler laststatus=2 showtabline=2 nomodifiable

highlight PlanHeader guifg=#ffffff guibg=#1d4ed8 gui=bold  ctermbg=26 ctermfg=white cterm=bold
highlight PlanKey    guifg=#fef08a guibg=#1d4ed8 gui=bold  ctermbg=26 ctermfg=229   cterm=bold
highlight PlanNav    guifg=#86efac guibg=#1d4ed8 gui=NONE  ctermbg=26 ctermfg=120   cterm=NONE

function! PlanTabline()
    let tl  = '%#PlanHeader# PLAN REVIEW %#PlanNav# § ${SECTION_NUM}/${TOTAL} %='
    let tl .= '%#PlanKey#Enter/n %#PlanNav#next  '
    let tl .= '%#PlanKey#p %#PlanNav#prev  '
    let tl .= '%#PlanKey#d %#PlanNav#done  '
    let tl .= '%#PlanKey#q %#PlanNav#ask  '
    let tl .= '%#PlanKey#e %#PlanNav#change '
    return tl
endfunction
set tabline=%!PlanTabline()
VIMSCRIPT

    tmux display-popup -E -w 95% -h 95% \
        "$EDITOR_CMD" -nR "$SECTION_FILE" -S "$vim_script" 2>/dev/null || true
}

# ── Nano popup + action menu ──────────────────────────────────────

open_nano_popup() {
    local menu_file="$TEMP_DIR/menu.sh"

    # View section in nano (read-only / view mode)
    tmux display-popup -E -w 95% -h 80% \
        "nano -v '$SECTION_FILE'" 2>/dev/null || true

    # Write action menu script with substituted paths
    cat > "$menu_file" << EOF
#!/bin/bash
SIGNAL_FILE="${SIGNAL_FILE}"
echo ""
echo "  Plan Review — Section ${SECTION_NUM} of ${TOTAL}"
echo "  ─────────────────────────────────────────────────"
echo "  n)  Next section"
echo "  p)  Previous section"
echo "  d)  Done (finish review)"
echo "  q)  Ask a question"
echo "  e)  Request a change"
echo ""
printf "  Choice: "
read -r -n1 choice
echo ""
case "\$choice" in
    p)
        echo "prev" > "\$SIGNAL_FILE"
        ;;
    d)
        echo "done" > "\$SIGNAL_FILE"
        ;;
    q)
        printf "  Question: "
        read -r q
        echo "ask:\$q" > "\$SIGNAL_FILE"
        ;;
    e)
        printf "  Describe change: "
        read -r c
        echo "change:\$c" > "\$SIGNAL_FILE"
        ;;
    *)
        echo "next" > "\$SIGNAL_FILE"
        ;;
esac
EOF
    chmod +x "$menu_file"

    tmux display-popup -E -w 50% -h 35% \
        "bash '$menu_file'" 2>/dev/null || true
}

# ── Dispatch ──────────────────────────────────────────────────────

case "$EDITOR_CMD" in
    nvim|vim) open_vim_popup ;;
    nano)     open_nano_popup ;;
    *)        open_vim_popup ;;
esac

# ── Output result ─────────────────────────────────────────────────

if [[ -f "$SIGNAL_FILE" ]]; then
    cat "$SIGNAL_FILE"
else
    echo "next"
fi

rm -rf "$TEMP_DIR"
