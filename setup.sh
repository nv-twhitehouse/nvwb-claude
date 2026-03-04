#!/bin/bash


# This installs the required apt packages
sudo apt install -y jq bubblewrap socat

# Installs necessary python package
pip install pyyaml

# This installs Claude Code in the project container
curl -fsSL https://claude.ai/install.sh | bash

# This creates the claude_audit_logs folder
mkdir -p ~/claude_audit_logs
