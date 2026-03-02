# Instructions to Human User

## Background

### Basic idea
1. This is a bare-bones template for a `~/.claude` folder in a Workbench project container
2. It's a basic example of how you might set Claude up in the project container
    -   The `settings.json` file has Workbench specific items already in it
        - It has `sandbox` enabled with a limited set of rules around blocking environment manipulation directly in the container
        - It also has some `permissions` set to `ask` for read/write blocks for various files an agent shouldn't modify without alerting the user
        - It also has a `hook` setup to block simple exfiltration attempts for `secret` environment variables
    - The `skills/nvidia-ai-workbench-container` subfolder has guidance on Workbench environment files and conventions
    - The `hooks` subfolder is there as a suggestion but is currently empty with an `empty.txt` file as a place holder
3. You can clone this repository into the container build with the `postBuild.bash` script
4. You STILL need to setup a `/project/.claude` folder in the repository, along with a `CLAUDE.md` file
5. You SHOULD add a persistent volume mount for `~/.claude` in the project container

### Fork this repository to make your own changes
1. This is a read-only public repository, so you can't make any edits to it 
2. Fork it to make your own version and do things like
    - Edit the `settings.json` file to your particular needs
    - Add any hooks you might want to the `hooks` subfolder and edit `settings.json` appropriately

#### NOTE
```
This repository does NOT contain any instructions or rules for how Claude uses the AI Workbench CLI **outside** of the container.
```

## Setup

### Pre-Requisites for the Project Container

1. REQUIRED: Install the following in the project container
    - Put in `apt.txt`: `jq`, `bubblewrap`, `socat`
        - `jq` is required for the `hooks` setup in `~/.claude/settings.json`
        - `bubblewrap` and `socat` are requirements for Claude `sandbox`
    - Put in `requirements.txt`: `pyaml`
        - `pyaml` is required for the `hooks` setup in `~/.claude/settings.json`
2. SUGGESTED: Add the following volume mounts to the project container for persistent storage across container **restarts**
    - `~/.claude`: Preserves settings and installed software across rebuilds and restarts
    - `/mnt/claude_audit_logs`: Preserves tool calling logs captured by the `hook` in `settings.json` across rebuilds and restarts

### Steps to Add this to the Project Container

1. Add the following commands **in order** to the top of your `postBuild.bash`
    - `sudo apt-get install -y bubblewrap socat`
        - These packages are necessary for the Claude sandbox to work
    - `git clone https://github.com/nv-twhitehouse/nvwb-claude ~/.claude`
        - Substitute your username/org on GitHub for `nv-twhitehouse` if you forked the original repository
    - ```
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo npm install -g @anthropic-ai/claude-code
      ```
2. Add a volume mount to persist the Claude install in the container (Desktop App)
    - **Project Tab > Project Container > Mounts > Add**
    - Select **Type > Volume Mount**
    - Enter **Target Directory >** `~/.claude` 
    - (optional) Enter **Description >** `Persisting Claude install and settings in the container`
3. Add another volume mount to persist tool calling logs in the container
    - **Project Tab > Project Container > Mounts > Add**
    - Select **Type > Volume Mount**
    - Enter **Target Directory >** `/mnt/claude_audit_logs` 
    - (optional) Enter **Description >** `Persisting tool calling logs in the container`
4. Then build the container in the Desktop App or CLI

#### Note

```
- If you are on API consumption billing for Anthropic, your token will be stored at `~/.claude.json`
- Workbench does not yet support mounting a single file to persist that token
- You may be tempted to mount the entire home folder, `~/`, in order to keep that token
- BUT DON'T DO THAT
- It will break pip installs because this will write over the packages installed into the container by Workbench
- This means you will need to reauthenticate everytime you fire up Claude in the container
- We will fix this in a future release 
```