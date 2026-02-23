# diffview

Open a side-by-side diff in a new tmux window using Neovim's DiffviewOpen
plugin.

## Command

```text
/stn:diffview [base]
```

- `/stn:diffview` — Compare current HEAD against `origin/main`
- `/stn:diffview origin/develop` — Compare against a different base
- `/stn:diffview HEAD~5` — Compare last 5 commits

## Requirements

- nvim with the
  [diffview.nvim](https://github.com/sindrets/diffview.nvim) plugin
- tmux
