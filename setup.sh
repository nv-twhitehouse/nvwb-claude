#!/bin/bash


# This installs the required apt packages
sudo apt install -y jq bubblewrap socat

# Installs necessary python package
pip install pyyaml

# This installs Claude Code in the project container
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g @anthropic-ai/claude-code

# This creates the claude_audit_logs folder
mkdir -p ~/claude_audit_logs
