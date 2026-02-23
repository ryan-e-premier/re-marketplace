# Diffview

Open a diff view in a new tmux window using Neovim's DiffviewOpen plugin.

## Usage

```
/re:diffview [base]
```

- `base` (optional): The base ref to compare against. Defaults to `origin/main`.

## Examples

- `/re:diffview` - Compare current HEAD against origin/main
- `/re:diffview origin/develop` - Compare against origin/develop
- `/re:diffview HEAD~5` - Compare last 5 commits

---

Open the diff in a new tmux window:

```bash
tmux new-window -n "diffview" "nvim -c 'DiffviewOpen ${1:-origin/main}...HEAD'"
```

Run this command and confirm it opened successfully.
