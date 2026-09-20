# ralph-loop-demo

This repo is a short tutorial on the most basic software factory: a **[Ralph
loop](https://ghuntley.com/ralph/)**. It runs a coding agent unattended, in a
fixed-size loop, so it builds a project from a spec one task at a time.

## Open it in a Dev Container or Codespace

The repository's [Dev Container](.devcontainer/devcontainer.json) uses Node.js
24 and installs Pi, Claude Code, and Codex. It contains no credentials.

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
claude

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
| `bin/run-agent` | Small adapter that selects Pi, Claude Code, or Codex |
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

Pi remains the default so the original command still works. Select another
agent for a single run with `--agent`, or set `RALPH_AGENT` in your shell:

```sh
./ralph.sh                     # Pi (default)
./ralph.sh --agent claude       # Claude Code
./ralph.sh --agent codex        # Codex
RALPH_AGENT=codex ./ralph.sh    # same selection through the environment
```

The adapter uses each CLI's documented non-interactive entry point: `pi -p`,
`claude -p "prompt"`, and `codex exec --approve-for-me "prompt"`. Codex's
`--approve-for-me` uses its workspace-write automatic-approval mode, so it can
edit the exercise workspace; review its changes as you would any unattended
agent's work. The adapter deliberately does not specify a model, so the selected
CLI uses the account/configuration you chose at login.

## What it's building

Peek in `spec.md` if you want the full brief — short version: a terminal
Tetris, started with `npm start`, that fits entirely — board, score, controls,
game-over message and all — inside 24 terminal rows.

## Now, the puzzle

Open `ralph.sh`. It's five lines of loop wrapped around one call that's been
left broken on purpose:

```sh
# call the selected agent in its non-interactive mode with the loop prompt
# TODO: un-comment the line below to make the loop work!
# bin/run-agent "$@" prompt.md
```

Fix the code by un-commenting that line, then run the loop with your selected
agent. It should take around 20 minutes to run to completion.

Install something like [watchexec](https://github.com/watchexec/watchexec) to
see the plan and code evolve while the agent is running.
