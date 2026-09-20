#!/usr/bin/env bash

for pass in 1 2 3 4 5; do
	echo "Pass $pass/5: starting..."

  # call the selected agent in its non-interactive mode with the loop prompt
  # TODO: un-comment the line below to make the loop work!
	# bin/run-agent "$@" prompt.md

	echo "Pass $pass/5: done"
done
