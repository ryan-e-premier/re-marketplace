#!/bin/bash
# Opens the current Claude Code conversation transcript in nvim via tmux popup

# Get the project path (current working directory or passed as argument)
PROJECT_PATH="${1:-$(pwd)}"

# Convert path to Claude's encoded format (replace / and _ with -)
ENCODED_PATH=$(echo "$PROJECT_PATH" | sed 's|^/||' | sed 's|/|-|g' | sed 's|_|-|g')

# Find the transcript directory
TRANSCRIPT_DIR="$HOME/.claude/projects/-$ENCODED_PATH"

if [ ! -d "$TRANSCRIPT_DIR" ]; then
    echo "Error: No transcript directory found at $TRANSCRIPT_DIR"
    exit 1
fi

# Find the most recently modified .jsonl file (current session)
LATEST_TRANSCRIPT=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST_TRANSCRIPT" ]; then
    echo "Error: No transcript files found in $TRANSCRIPT_DIR"
    exit 1
fi

# Format the transcript to readable markdown
SCRIPT_DIR="$(dirname "$0")"
FORMATTED_FILE="/tmp/claude-transcript-$(basename "$LATEST_TRANSCRIPT" .jsonl).md"

# Format content
"$SCRIPT_DIR/format-transcript.sh" "$LATEST_TRANSCRIPT" > "$FORMATTED_FILE"

# Create vim script for styling
VIM_SCRIPT="/tmp/claude-transcript-view.vim"
cat > "$VIM_SCRIPT" << 'VIMSCRIPT'
" Claude Code Transcript Viewer - Enter to close

" Close function
function! ClaudeClose()
    qa!
endfunction

" Enter or q to close
nnoremap <CR> :call ClaudeClose()<CR>
nnoremap q :call ClaudeClose()<CR>

" Custom highlight groups matching diff-review style
highlight ClaudeTitle guifg=#ffffff guibg=#7c3aed gui=bold ctermbg=93 ctermfg=white cterm=bold
highlight ClaudeKey guifg=#facc15 guibg=NONE gui=bold ctermfg=yellow cterm=bold
highlight ClaudeClose guifg=#60a5fa guibg=NONE gui=bold ctermfg=blue cterm=bold

" Winbar with colors
set winbar=%#ClaudeTitle#\ \ 📜\ TRANSCRIPT\ \ %*%=%#ClaudeKey#Enter%#ClaudeClose#\ Close\ \

" Read-only and no modifications
set nomodifiable
set readonly

" Start at the bottom (newest content)
normal G
VIMSCRIPT

# Open formatted transcript in tmux popup
tmux popup -w 80% -h 80% -E "nvim '$FORMATTED_FILE' -S '$VIM_SCRIPT'"
