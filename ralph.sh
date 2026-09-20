#!/usr/bin/env bash

for pass in 1 2 3 4 5; do
	echo "Pass $pass/5: starting..."

  # TODO: choose exactly one agent and un-comment its line to make the loop work.
	# pi -p < prompt.md
	# claude -p "$(cat prompt.md)"
	# codex exec --approve-for-me "$(cat prompt.md)"

	echo "Pass $pass/5: done"
done
