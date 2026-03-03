#!/bin/bash

# Checks on the append only log file, and if not there then creates it and sets it to append only.

mkdir -p ~/claude_audit_logs

if [ ! -f ~/claude_audit_logs/claude-audit.jsonl ]; then 
   jq -n -c '{ts: (now | todate), session: "n/a", event: "container_start", tool: "n/a", sandbox_disabled: false, target: "n/a"}' >> ~/claude_audit_logs/claude-audit.jsonl
   sudo chattr +a ~/claude_audit_logs/claude-audit.jsonl
else
   jq -n -c '{ts: (now | todate), session: "n/a", event: "container_start", tool: "n/a", sandbox_disabled: false, target: "n/a"}' >> ~/claude_audit_logs/claude-audit.jsonl
fi

if [ ! -d /project ]; then
   exit 0
fi


if [ ! -f /project/CLAUDE.md ]; then
   echo "# Use this file to instruct Claude in the project repo" > /project/CLAUDE.md
fi

if [ ! -d /project/.claude ]; then
    mkdir /project/.claude
fi
