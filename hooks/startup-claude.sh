#!/bin/bash


# Record directory session started in to determine applicable rules
echo $(pwd) > /tmp/claude_start_dir

# Check if Claude is in a project container; 
if [ ! -f /project/.project/spec.yaml ]; then
   echo "Not in a Workbench project container; Ignore Workbench skills in skills/ai-workbench-container"
   exit 0
fi

echo -e "This is the project spec.yaml file.\n"
cat /project/.project/spec.yaml 

# Check if we are in a container with GPUs mounted
if command -v nvidia-smi &>/dev/null && nvidia-smi &> /dev/null; then
   echo -e "There are GPUs available in this container. See `nvidia-smi` output below.\n"
   nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader
fi
