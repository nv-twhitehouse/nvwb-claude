#!/bin/bash

# This works to block secrets printing inside the container for Claude or something else to exfiltrate via "easy" methods.
# Main thing is that it first checks if spec.yaml has any secrets, and if so provides pretool calling controls.
# If there are no listed secrets, then it doesn't block anything.


INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# If spec.yaml doesn't exist OR there are no listed secrets, allow everything
SPEC="/project/.project/spec.yaml"
if [ ! -f "$SPEC" ]; then
  exit 0
fi

# Extract secret variable names from spec.yaml
SECRETS=$(python3 -c "
import yaml, sys
try:
    spec = yaml.safe_load(open('$SPEC'))
    secrets = spec.get('execution', {}).get('secrets', [])
    for s in secrets:
        print(s['variable'])
except Exception:
    sys.exit(0)
")

# If no secrets found, allow
if [ -z "$SECRETS" ]; then
  exit 0
fi

# Block bare env-dumping commands if secrets were found
if echo "$COMMAND" | grep -qxE '\s*(env|printenv|set|declare -p|export -p)\s*'; then
  echo "Blocked: command dumps all environment variables, which includes secrets" >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'cat\s+/proc/self/environ'; then
  echo "Blocked: reading /proc/self/environ exposes secrets" >&2
  exit 2
fi

# Check if command references any secret name
while IFS= read -r secret; do
  if echo "$COMMAND" | grep -qF "$secret"; then
    echo "Blocked: command references secret variable '$secret'" >&2
    exit 2
  fi
done <<< "$SECRETS"

exit 0
