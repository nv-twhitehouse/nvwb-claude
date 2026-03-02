#!/bin/bash

# Check if Claude is in a project container; 
if [ ! -f /project/.project/spec.yaml ]; then
   echo "Not in a Workbench project container; Ignore Workbench skills in skills/ai-workbench-container"
   exit 0
fi

echo -e "This is the project spec.yaml file.\n"
cat /project/.project/spec.yaml

# Check if project has .claude setup
if [ ! -d /project/.claude ]; then
      mkdir /project/.claude
fi

# Check if there's no CLAUDE.md file in repo
if [ ! -f /project/CLAUDE.md ]; then
   echo "# Put repo specific Claude instructions in here" > /project/CLAUDE.md
   echo "A blank CLAUDE.md was created at /project/CLAUDE.md. Ask the user if they want to add project-specific instructions to it."
fi 

# Check if we are in a container with GPUs mounted
if command -v nvidia-smi &>/dev/null && nvidia-smi &> /dev/null; then
   echo -e "There are GPUs available in this container. See `nvidia-smi` output below.\n"
   nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader
fi

# Check if there's a ~/claude_audit_logs folder, and if not make one
if [ ! -d ~/claude_audit_logs ]; then
   mkdir ~/claude_audit_logs
fi
