# Instructions to Human User

## Background

### Basic Idea
1. This is a bare-bones template to get started with Claude in a Workbench project container
2. The main goal is are to demo sandboxing, permissions configuration and hooks for Claude Code in a Workbench friendly way
3. It assumes you will want to start a project container, and then start Claude within that container
    - It's not built to work with Claude running outside of the project container
4. It has the "essential" bits for the `~/.claude` folder that determines Claude behavior at the user level
    - Note that Claude has a subtle settings hierarchy that partially relies on which folder you initiate the session from
5. The overall procedure is to clone this repository in the `postBuild.bash` script and run some commands for setup 
6. The sandbox, permissions and hooks assume that everything is relatively trusted and you are trying to prevent accidents and oversites
    - They aren't perfect so don't treat them as such
7. You can/should fork this to make your own adaptations.

### Repository Structure
1. Top level
    - `settings.json`: Configuration file for Claude 
    - `entrypoint.sh`: Entrypoint script that Workbench runs on container start to do some basic setup for Claude that can't be done during build
    - `setup.sh`: Script run in `postBuild.bash` that installs Claude Code during the build and setups up a few folders
    - `hooks/`: Folder with hook scripts used in `settings.json`
    - `skills/`: Folder with skills
2. Hooks folder
    - `startup-claude.sh`: Script that runs on starting a Claude Code session
        - Records the folder from which the Claude session was started 
        - Checks if the container is a project container
        - Checks if there are GPUs mounted
        - Feeds this information into Claude's context
    - `block-secrets-in-bash.sh`: Script that blocks simple leaks of secrets declared in `spec.yaml` into Claude's context
3. Skills folder
    - Currently has a single folder for AI Workbench, `ai-workbench-container`
    - `references/`: Currently has a single file, `config-files.md`

## How to Get Started
1. Fork this repository so you can make and keep your own edits
2. Add the following commands to your `postBuild.bash` file
    - ```
        git clone https://github.com/<your-github-username>/nvwb-claude ~/.claude
        mv ~/.claude/entrypoint.sh ~/.claude/setup.sh ~/
        bash ~/setup.sh
      ```
3. Add the following volume mounts to the project in the Workbench Desktop App or CLI 
    - `~/.claude` to persist settings and changes between container restarts
        - **Project Tab > Project Container > Mounts > Add**
        - Select **Type > Volume Mount**
        - Enter **Target Directory >** `~/.claude` 
        - (optional) Enter **Description >** `Persisting Claude install and settings in the container`
    - `~/claude_audit_logs` to persist a relatively tamper proof set of logs for tool calls
        - **Project Tab > Project Container > Mounts > Add**
        - Select **Type > Volume Mount**
        - Enter **Target Directory >** `~/claude_audit_logs` 
        - (optional) Enter **Description >** `Persisting logs in the container`
4. Add the entrypoint script location to the `spec.yaml` file so Workbench knows to use it at runtime
    - Open the `.project/spec.yaml` file with a file editor
    - Edit the `environment.base.entrypoint_script` field to have the following value
        - `"/home/workbench/entrypoint.sh"`
    - Save the changes to the `spec.yaml` file
5. Build the container
    - **Project Tab > Project Container > Build**

 ### Things You Can/Should Modify
  1. `settings.json` > `permissions`: Add `ask`, `allow`, or `deny` rules for specific tools and commands
  2. `settings.json` > `sandbox`: Adjust filesystem read/write block lists for your project
  3. `settings.json` > `hooks`: Add your own hooks for any lifecycle event (SessionStart, PreToolUse, PostToolUse,
  UserPromptSubmit, etc.)
  4. `settings.json` > `model`: Change the default model from `claude-opus-4-6` if desired
  5. `hooks/`: Add new scripts and reference them in `settings.json` hooks
  6. Logging: Develop a better logging approach that accurately tracks which settings hierarchy is active for a session


## Be Aware of the Following

### Settings Hierarchy for Claude Code

1. Settings are applied/merged in the following order, with managed settings being absolute
    a. Managed (usually in `/etc/claude-code/managed-settings.json` or sometimes in `~/.claude/remote-settings.json`)
    b. Project Local (`/project/.claude/settings.local.json`)
    c. Project Shared (`/project/.claude/settings.json`)
    d. User level (`~/.claude/settings.json`)
2. However, the applicable settings files **for the session** depend on **where** the session starts
    - Session starts in `~/`: Managed > User Level apply; project level settings not relevant
    - Session starts in `/project`: Managed > Project Local > Project Shared > User Level apply
    - Session starts anywhere else: Managed only
3. Keep this in mind for `sandbox` status
    - `sandbox.enabled` set to `true` trumps in the hierarchy
    - But, which `sandbox.enabled` settings values apply depends on the session start folder 

### Tool Logging

1. This setup uses Claude Code hooks declared in `~/.claude/settings.json` to log tool calls to the file `~/claude_audit_logs/claude-audit.jsonl`
    - The folder `~/claude_audit_logs` is created by `setup.sh` on container build
    - The file `claude-audit.jsonl` is created/checked by `entrypoint.sh` on container start
    - Each entry is a JSON object with: timestamp, session ID, event type, tool name, sandbox status, and target
        - Sandbox status isn't handled well due to the edge cases in the hierarchy above, and isn't reliable
2. The `entrypoint.sh` script sets the log file to **append-only** (`chattr +a`) on first container start
    - Existing log entries cannot be modified in the running container due to no `sudo` permissions
    - Entries will be appended by the hook as it runs
3. Persistence across container starts or rebuilds requires a volume mount on `~/claude_audit_logs`
    - Without it, logs are lost on container restart
    - With it, logs accumulate across restarts and rebuilds

### Authentication

1. If your Anthropic account uses API Consumption billing, then you will need to **reauthenticate** everytime you start the container
    - This is unfortunate but based on the fact that the Oauth configuration is saved to `~/.claude.json`, which is **not** in the `~/.claude` mount
    - You may be tempted to mount the entire `~/`, but DON'T because it will break how Workbench does `pip` installs
2. If you are using a different billing method, then authentication will persist between container rebuilds and restarts if you create the `~/.claude` mount
    - This would involve starting Claude Code in the project container and then following the Oauth flow, where the configuration is saved into the mount
    - Alternatively, you can setup a token as a secret (`ANTHROPIC_API_KEY`) and that should be loaded on container start
    - However, DON'T use the secret AND the Oauth method as this will break things.
