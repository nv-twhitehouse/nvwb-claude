---
name: nvwb-project
description: Apply when working in a Linux environment that has a `/project/.project/spec.yaml` file — provides NVIDIA AI Workbench project awareness for in-container development. This skill provides context about project structure, environment configuration, and rebuild/restart requirements.
user-invocable: false
---

# NVIDIA AI Workbench — In-Container Project Awareness

This skill activates when Claude is working inside an AI Workbench project container, detected by the file `/project/.project/spec.yaml` existing in or above the current working directory.

The AI Workbench project container is running on a HOST, and the container is managed by AI Workbench on that HOST.

## Detection

- Check the existence of the file `/project/.project/spec.yaml`. 
- If it exists, then you are working in an AI Workbench Project container and you should use this skill.
- If it does not exist, then you are NOT working in an AI Workbench Project container and you should NOT use this skill. 

Read the `/project/.project/spec.yaml` file first to understand the project's layout, apps, mounts, and resources.

## Key Facts

- AI Workbench is a development environment manager that is running OUTSIDE of the container on the host.
- AI Workbench manages the container build and runtime, as well as the project Git repository `/project/`.
- The `/project/` folder is a Git repository inside the container that is read/write bind mounted to the HOST file system
- The `/project/.project/spec.yaml` file is a versioned specification file that provides information about the project repository ('/project/`), container environment, and runtime configuration.
- The environment may have sensitive environment variables declared in the `execution.secrets` section of `spec.yaml`. Only the variable names and descriptions are stored in the spec — the actual values are stored separately on the host, outside the repository, and injected into the container at runtime.
- The project container is built from the base image that is defined by the URL in the related field in the `spec.yaml` file.
- The `/project/` folder may have environment configuration files like `requirements.txt`, `apt.txt`, `postBuild.bash`, and `preBuild.Bash`. If they are there, those files define the environment built in the container.
- AI Workbench uses the environment configuration files while building the container by including them in a Dockerfile that AI Workbench creates and manages OUTSIDE of the project repository.
- The `/project/` folder is the only guaranteed persistent storage in the container, so file writes outside of it may not persist. 
- There may be other persistent storage in the container in the form of bind mounts to the host or volumes. You can detect those mounts in the `/project/.project/spec.yaml` file.
- There may be Docker Compose services running alongside the project container. The compose file location is set in `environment.compose_file_path` in `spec.yaml` (path relative to project root). If the field is empty, no compose services are configured.
- Compose services and the project container share a Docker network — services are reachable by service name (e.g. `curl http://api:8080/`).
- `/nvwb-shared-volume/` is shared between the project container and compose services.
- Compose is managed through the AI Workbench Desktop App or `nvwb` CLI on the host — not from inside the container.
- You cannot trigger a container rebuild from within the container. You will need to ask the user to do it or use a particular tool to make the request.
- There may be a `/project/.agent-bridge/` subfolder. If so, then you may use that to communicate with an agent running on the host.
- The user in the container does NOT have `sudo` privileges
- AI Workbench has a Desktop App where users can manage the container.
- AI Workbench has a CLI named `nvwb` that they or an agent can use to manage the container.
- The Desktop App and CLI are NOT available in the container.

## What NOT to Do

- Do NOT try to use `sudo` privileges in the container
- Do NOT try to install any packages in the container
- Do NOT edit anything in the `.project` subfolder without consulting the user
- Do NOT try and run any sort of `nvwb` command in the container because it will fail

# What To Do

- Ask the user to restart or rebuild the container for you when you need it
- Ask the user to install packages for you when needed
- Read the `spec.yaml` file to help you understand the repository and container

## What's Safe to Edit

**Freely editable** — no consultation to user needed:
- Any files in the `/project/` folder EXCEPT for the `.project` subfolder.
- Application code, scripts, notebooks

**Requires container rebuild** — consult the user before editing them:
- `apt.txt` — system packages
- `requirements.txt` — pip packages
- `preBuild.bash` — pre-install build script
- `postBuild.bash` — post-install build script

**Requires compose restart** — inform the user after editing:
- `compose.yaml` / `docker-compose.yml` — stop and restart compose environment in the Desktop App

**Requires container restart** — consult the user before editing them:
- `variables.env` — runtime environment variables
- Mount configuration changes in `.project/spec.yaml`
- App definitions in `.project/spec.yaml`

**Edit carefully** — consult the user before editing them and follow convenstions:
- `.project/spec.yaml` — do not break YAML structure; suggest user to run `nvwb validate project-spec` after changes

## When Informing the User

After editing a build-time or runtime file, always tell the user what action is needed. Examples:

> I've updated `requirements.txt` to add the `transformers` package. You'll need to rebuild the container to effectuate this change.

> I've added `CUDA_VISIBLE_DEVICES=0` to `variables.env`. This will take effect after a container restart — restart the container to effectuate them.

> I've updated `compose.yaml` to add a vector database service. You'll need to stop and restart the compose environment in the Desktop App for this to take effect.

## Compose Awareness

Multi-container environments use Docker Compose (v2 syntax) to run services alongside the project container. Common use cases include inference APIs, databases, vector stores, and full AI pipelines (e.g. RAG systems).

### How compose integrates with AI Workbench

- The compose file location is set in `environment.compose_file_path` in `spec.yaml` (relative to project root, e.g. `compose.yaml` or `deploy/compose.yaml`). An empty string means no compose services.
- The compose file is versioned in Git with the project. Container images are not — they are pulled by tag at runtime.
- AI Workbench provides Desktop App controls to start, stop, and monitor compose services. The `nvwb` CLI can also manage compose (`nvwb compose up`, `nvwb compose down`, etc.) on the host.
- You cannot manage compose from inside the container. Ask the user to start/stop services, or use the agent bridge to request it.

### Networking and shared storage

- All compose services and the project container share a Docker network. Services are reachable by service name as hostname (e.g. `curl http://api:8080/`).
- `/nvwb-shared-volume/` is shared between the project container and compose services.

### Sensitive environment variables

- Sensitive environment variables are declared in `execution.secrets` in `spec.yaml` (names and descriptions only). Their values are stored on the host outside the repository and injected at runtime.
- Compose services can reference these variables using `${VARIABLE_NAME}` syntax in their environment sections. AI Workbench passes them to compose at startup, keeping sensitive values out of version control.

### Proxy integration

- Web services that users access through a browser can be proxied through AI Workbench by setting `NVWB_TRIM_PREFIX: "true"` in the service's environment variables (in the compose file, not in spec.yaml). Access URLs appear in the Desktop App.
- Backend APIs, databases, and internal services should not set this variable.

### GPU access for compose services

- Compose services can request GPUs using standard Docker Compose `deploy.resources.reservations.devices` syntax with `runtime: nvidia`.
- Use `count` to request a number of GPUs, or `device_ids` (e.g. `['0']`, `['1', '2']`) to assign specific GPUs.
- Ensure compose GPU assignments don't conflict with GPUs used by the project container.

### Profiles

- Compose files can define profiles to enable conditional service activation (e.g. `small-model` vs `large-model`, or optional components).
- Services with a `profiles` tag only start when that profile is selected. Services without profiles always start.
- Profiles are selected in the Desktop App before starting the compose environment.

### Editing compose files

- The compose file can be edited freely — it lives in the project repository.
- Changes to the compose file require stopping and restarting the compose environment to take effect. Ask the user to do this, or request it via the agent bridge.

## Host↔Container Bridge

If `/project/.agent-bridge/` exists, this project is set up for communication between inner Claude (here, in the container) and outer Claude (on the user's local machine, where `nvwb` is installed).

**When you need a local-machine action** (compose restart, rebuild, `nvwb` command):
1. Read `common-context/context.md` for current task state
2. Write a clear request to `/project/agent-bridge/inner.md`
3. Wait for the user to relay it to outer Claude on their local machine
4. Read the response from `/project/agent-bridge/outer.md`

**Rules**: Do not copy files into or out of `/project/.agent-bridge/` — it is a communication channel, not a file staging area. The content of `inner.md` and `outer.md` is unrestricted — include logs, snippets, and diagnostics as needed.

**Sandbox**: If hooks are configured, your actions are enforced — `nvwb` commands are blocked (use the bridge), sensitive environment variables are scrubbed from your shell commands, writes inside `agent-bridge/` are restricted to your designated files, and reads of sensitive files and hook configuration are blocked. Do not attempt to modify hook configuration or settings files.

Note: if this project is running in a remote context, the bridge files live on the remote machine. The context name (from `nvwb list contexts`) is also the SSH alias — Workbench adds a matching entry to `~/.ssh/config`. Outer Claude can SSH directly using the context name to read and write bridge files without involving the user as a relay.

Requests can be rich prose — include what you changed, what you need done, and what you want reported back (logs, curl output, etc.).

See `references/agent-bridge.md` for templates and the full format guide.

## Runtime Constraints

**`sudo` is typically NOT available in the running container** — the container typicall runs as the `workbench` user without elevated privileges at runtime. If a task requires system-level changes, it must go in `preBuild.bash` or `postBuild.bash`.

## Build Script Constraints

Build scripts (`preBuild.bash`, `postBuild.bash`) run during container image build:
- They CANNOT reference `/project/` — the project directory is not mounted during build
- Available variables: `$NVWB_UID`, `$NVWB_GID` for file ownership
- **Both scripts run as the `workbench` user (not root)** — any write to a system directory requires `sudo`. This includes `mkdir`, `npm install -g`, writing to `/usr/local/`, etc. Shell redirections (`>`, `>>`) also run as `workbench`, so use `sudo tee` instead of `sudo command > /path`.
- HOWEVER, `sudo` is available during the container build so you can run commands as root in the scripts if needed.

## References

See `references/config-files.md` for detailed information about each configuration file.
