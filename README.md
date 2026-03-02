# Instructions to Human User

## Background

**Basic idea**
1. This is a bare-bones template for a `~/.claude` folder in a Workbench project container
2. The `settings.json` file has Workbench specific items already in it
    - It has `sandbox` enabled
    - That `sandbox` has a limited set of enforced rules, mostly around blocking environment manipulation directly in the container
    - It also has some sensible read/write blocks for various files an agent shouldn't modify without alerting the user
3. The `skills/nvidia-ai-workbench-container` folder has guidance on Workbench environment files and conventions
4. The `hooks` subfolder is there as a suggestion but is currently empty
4. You can clone this repository into the container build with the `postBuild.bash` script BEFORE installing Claude Code in the container
5. Starting Claude Code or invoking Claude in the container will use this folder and will add any necessary missing files or folders
5. You STILL need to setup a `.claude` folder in the top of the project repository, along with a `CLAUDE.md` file
6. You SHOULD add a persistent volume mount for the target `~/.claude` in the project container

**You can/should:**
1. Fork this directory to make your own edits to it, including adding other folders to the `skills` subfolder if you need them
2. Edit the `settings.json` file to your particular needs
3. Add any hooks you might want to use for all of your projects to the `hooks` subfolder and editing `settings.json` appropriately

## Setup

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
2. Add a volume mount to project in the Desktop App or using the CLI
    - **Project Tab > Project Container > Mounts > Add**
    - Select **Type > Volume Mount**
    - Enter **Target Directory >** `~/.claude` 
    - (optional) Enter **Description >** `Locally persisting Claude install and settings`
3. Then build the container in the Desktop App or CLI

## Note

```
- If you are on API consumption billing for Anthropic, your token will be stored at `~/.claude.json`
- Workbench does not yet support mounting a single file to persist that token
- You may be tempted to mount the entire home folder, `~/`, in order to keep that token
- BUT DON'T DO THAT
- It will break pip installs because this will write over the packages installed into the container by Workbench
- This means you will need to reauthenticate everytime you fire up Claude in the container
- We will fix this in a future release 
```