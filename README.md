# Instructions to Human User

## Background

### Basic idea
1. This is a bare-bones template for a `~/.claude` folder in a Workbench project container
2. It's a basic example of how you might set Claude up in the project container
    -   The `settings.json` file has Workbench specific items already in it
        - It has `sandbox` enabled with a limited set of rules that block some file writes and reads for settings.json and related files.
        - It also has some `permissions` set to `ask` for read/write blocks for various files an agent shouldn't modify without alerting the user
        - It also has an example hook that will log tool calls to `/mnt/claude_audit_logs` in the container
        - It also has a `hook` setup to block simple exfiltration attempts for `secret` environment variables
    - The `skills/nvidia-ai-workbench-container` subfolder has guidance on Workbench environment files and conventions
    - The `hooks` subfolder has two scripts
        - `block-secrets-in-bash.sh` runs as a `PreToolUse` hook to help prevent secret environment variables from leaking
        - `startup-claude.sh` runs on initiating Claude Code to get some basic info on the container:
            - Checks if it's a project container
            - Checks for existing `/project/.claude` and `/project/CLAUDE.md` files, and adds them if not
            - Prints `/project/.project/spec.yaml` into Claude's context if there
            - Runs and parses `nvidia-smi` to see if/what GPU are mounted in the container
            - Checks if the log folder exists, and if not makes it
    - The settings maintain a log of tools called and permission requests at `~/claude_audit_logs`
        - This is only persisted if you set that up as a volume mount (or host mount if desired)
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
    - `/home/workbench/claude_audit_logs`: Preserves tool calling logs captured by the `hook` in `settings.json` across rebuilds and restarts

### Steps to Add this to the Project Container

1. Add the following commands **in order** to the top of your `postBuild.bash`
    - `git clone https://github.com/nv-twhitehouse/nvwb-claude ~/.claude`
        - Substitute your username/org on GitHub for `nv-twhitehouse` if you forked the original repository
    - ```
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo npm install -g @anthropic-ai/claude-code
      ```
2. Add a volume mount to persist the Claude install in the container (Use Desktop App)
    - **Project Tab > Project Container > Mounts > Add**
    - Select **Type > Volume Mount**
    - Enter **Target Directory >** `~/.claude` 
    - (optional) Enter **Description >** `Persisting Claude install and settings in the container`
3. Add another volume to persist the tool calling logs in the container (Use Desktop App)
    - **Project Tab > Project Container > Mounts > Add**
    - Select **Type > Volume Mount**
    - Enter **Target Directory >** `~/claude_audit_logs` 
    - (optional) Enter **Description >** `Persisting record of Claude tool calls in the container`
        - Note: This is not a tamper proof log.
4. Then build the container in the Desktop App or CLI

#### Note

```
- If you are on API consumption billing for Anthropic, then you can't really save your `claudeAiOauth` credential because it's hard coded to be saved at `~/.claude.json`. Other OAuth setups save it to `~/.claude/.credentials.json` which is persisted by the mount.
- Workbench does not yet support mounting a single file to persist that token, so you will have to restart everytime or figure out some sort of simlink
- You may be tempted to mount the entire home folder, `~/`, in order to keep that token, BUT DON'T DO THAT
- It will break pip installs because mounting the entire home folder will cause problems when Workbench goes to install `pip` packages there
- We will fix this in a future release
- If you are on another billing plan, you shouldn't have to worry about this and the credentials will persist in `~/.claude` 
```