#!/bin/bash

# This preserves the current auth information so that it's not deleted when the container restarts.

cp ~/.claude.json ~/.claude/.claude.json

