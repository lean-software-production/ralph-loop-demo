# ralph-loop-demo

This repo is a short tutorial on the most basic software factory: a **[Ralph
loop](https://ghuntley.com/ralph/)**. It runs a coding agent unattended, in a
fixed-size loop, so it builds a project from a spec one task at a time.

## Open it in a Dev Container or Codespace

The repository's [Dev Container](.devcontainer/devcontainer.json) uses Node.js
24 and installs Pi, Claude Code, and Codex. It also installs the optional
[OpenAI Codex VS Code extension](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt)
in the container extension host. It contains no credentials.

- **GitHub Codespaces:** use **Code → Create codespace on main**, then open an
  integrated terminal after creation.
- **VS Code:** clone this repository, install the Dev Containers extension, and
  choose **Dev Containers: Reopen in Container**.

The container runs as the non-root `node` user. Authenticate *after* it is
created, in that user's terminal; never add a token, API key, or home-directory
credential file to this repository.

```sh
# Pi: start it, then type /login at the Pi prompt.
pi

# Claude Code: follow the interactive browser sign-in.
claude auth login

# Codex: the device flow works in Codespaces and remote containers.
codex login --device-auth
```

Then run the read-only readiness check:

```sh
bin/doctor                 # report every agent; one configured agent is enough
bin/doctor --agent pi      # require Pi
bin/doctor --agent claude  # require Claude Code
bin/doctor --agent codex   # require Codex
bin/doctor --agent all     # require all three
```

`bin/doctor` checks Node, npm, Git, the exercise scripts, every installed CLI,
and non-secret configuration indicators. It does not print or parse credentials
and does not send a prompt or make a paid model call. `NO_COLOR=1 bin/doctor`
or `bin/doctor --no-color` is suitable for logs. `./setup` is a compatibility
alias for this same check; it no longer spends tokens to test an agent.

## The pieces

| File | What it is |
| --- | --- |
| `spec.md` | The project the loop is trying to build |
| `prompt.md` | Instructions to the agent on each pass of the loop |
| `plan.md` | Doesn't exist yet — the agent writes it on pass 1 |
| `ralph.sh` | Turns the crank a fixed number of times |

Study [ralph.sh](./ralph.sh) and [prompt.md](./prompt.md) to understand the flow
of the loop:

Every pass, the agent reads `prompt.md` and looks around:

1. **No `plan.md`?** Read `spec.md`, break the work into four even-sized tasks,
   write them to `plan.md`.
2. **`plan.md` already there?** Find the first task not yet marked done, do
   *only* that one, check it off, stop.

Same instructions each time. The state lives on disk, not in the agent's head.
Run the loop enough times and the plan finishes itself.

## Choose an agent

Choose directly in `ralph.sh`: it contains one commented non-interactive command
for each agent. Un-comment **exactly one** line, then run `./ralph.sh`. The lines
use `pi -p`, `claude -p "$(cat prompt.md)"`, and
`codex exec --approve-for-me "$(cat prompt.md)"`. Codex's
`--approve-for-me` uses its workspace-write automatic-approval mode, so it can
edit the exercise workspace; review its changes as you would any unattended
agent's work. None of the commands specifies a model, so the chosen CLI uses
the account/configuration selected at login.

## What it's building

Peek in `spec.md` if you want the full brief — short version: a terminal
Tetris, started with `npm start`, that fits entirely — board, score, controls,
game-over message and all — inside 24 terminal rows.

## Now, the puzzle

Open `ralph.sh`. It's five lines of loop wrapped around three possible calls,
all left broken on purpose:

```sh
# TODO: choose exactly one agent and un-comment its line to make the loop work.
# pi -p < prompt.md
# claude -p "$(cat prompt.md)"
# codex exec --approve-for-me "$(cat prompt.md)"
```

Fix the code by un-commenting one line, then run the loop. It should take
around 20 minutes to run to completion.

Install something like [watchexec](https://github.com/watchexec/watchexec) to
see the plan and code evolve while the agent is running.
