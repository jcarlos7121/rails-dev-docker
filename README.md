# Ruby on Rails Docker-based Development Environment

## Requirements

- Docker
- Mise
- Neovim (optional)
- Github CLI (optional, set GH_TOKEN securely in your environment)

## Installation

`curl -fsSL https://raw.githubusercontent.com/jcarlos7121/rails-dev-docker/main/.scripts/bootstrap.sh | sh -s -- [-p prefix] user/repo`

- `prefix` = optional name for project/folder (will use repo name by default)
- `user/repo` = Github user/repo (or a full URL to git repository)

## Mise tasks

Run from a worktree directory unless noted otherwise. Aliases shown in parentheses.

_Tip: Set a shell alias for "mise run" to "mr"._

### Lifecycle

- `mise run up` (`u`) — start the app (ensures external volumes, brings up the proxy first)
- `mise run proxy:up` (`proxy`) — start the shared Traefik proxy
- `mise run proxy:down` — stop the proxy
- `mise run proxy:logs` — tail proxy logs
- `mise run destroy` — remove every docker resource for this project and delete the project folder (run from project root or a worktree; prompts for confirmation)

### Worktrees

- `mise run wt <branch | PR# | new-branch>` — create a new git worktree with its own mise.local.toml and ports
- `mise run wt:ls` — list all worktrees
- `mise run wt:open [browser]` — open the current worktree URL (`xdg-open` by default)

### Development

- `mise run rails` — open a zsh shell in the running app container
- `mise run console` (`c`) — Rails console
- `mise run nvim` (`v`) — connect to the in-container Neovim via `--remote-ui`
- `mise run claude` (`ai`) — run Claude Code in the `claude` container (new Kitty tab if running inside Kitty, otherwise in the current terminal)
- `mise run claude:rebuild` — rebuild the Claude container with the latest Claude Code

### Tests / CI

- `mise run test` (`t`) — Retest watcher
- `mise run rails_tests [args]` (`rt`) — `bin/rails test`
- `mise run rails_sytem_tests [args]` (`rst`) — `bin/rails test:system`
- `mise run ci` — full CI lint + test pass (`rake ci:build:commit`)

### Database / RustFS snapshots

- `mise run db:dump` — dump dev DB and RustFS data into `.docker-config/db-dumps/` for fast container restarts
- `mise run db:dump:clear` — remove dump files so the next start does a full `db:prepare`
