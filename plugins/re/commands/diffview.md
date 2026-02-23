# Diffview

Open a diff view in a tmux popup using Neovim's DiffviewOpen plugin.

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

Open the diff in a tmux popup:

```bash
tmux display-popup -E -w 95% -h 95% "nvim -c 'DiffviewOpen ${1:-origin/main}...HEAD'"
```

Run this command and confirm it opened successfully.
