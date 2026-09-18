# ralph-loop-demo

This repo is a short tutorial on the most basic software factory: a **[Ralph 
loop](https://ghuntley.com/ralph/)**. It runs a coding agent unattended, in a fixed-size loop, so it builds 
a project from a spec one task at a time, autonomously.

## Getting started

```sh
./setup
```

This just confirms the [`pi`](https://pi.dev) CLI is installed and
answers correctly.

If you've never used Pi before you may need to run it an use `/login` to authenticate
with a model provider.

## The pieces

| File        | What it is                                                       |
|-------------|------------------------------------------------------------------|
| `spec.md`   | The project the loop is trying to build                          |
| `prompt.md` | Instructions to the agent on each pass of the loop               |
| `plan.md`   | Doesn't exist yet — the agent writes it on pass 1                |
| `ralph.sh`  | Turns the crank a fixed number of times                          |

Study [ralph.sh](./ralph.sh) and [prompt.md](./prompt.md) to understand the flow
of the loop:

Every pass, the agent reads `prompt.md` and looks around:

1. **No `plan.md`?** Read `spec.md`, break the work into four
   even-sized tasks, write them to `plan.md`.
2. **`plan.md` already there?** Find the first task not yet marked
   done, do *only* that one, check it off, stop.

Same instructions each time. The state lives on disk, not in the
agent's head. Run the loop enough times and the plan finishes itself.

## What it's building

Peek in `spec.md` if you want the full brief — short version: a
terminal Tetris, started with `npm start`, that fits entirely — board,
score, controls, game-over message and all — inside 24 terminal rows.

## Now, the puzzle

Open `ralph.sh`. It's five lines of loop wrapped around one call that's
been left broken on purpose:

```sh
# call pi in "headless mode" passing it the prompt to run the loop
# TODO: un-comment the line below to make the loop work!
# pi -p < prompt.md
```

Fix the code by un-commenting that line, then run the loop:


```sh
./ralph.sh
```

It should take around 20 minutes to run to completion.

Install something like https://github.com/watchexec/watchexec to see the plan and code evolve while the agent is running.

