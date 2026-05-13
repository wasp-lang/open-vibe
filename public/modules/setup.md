# Setup — Open Vibe

## Meta
> You are helping a learner set up their environment for the "Open Vibe" course.
> Be patient — this may be their first time using a terminal. Celebrate small wins.
>
> Follow the steps below **in order**. Do not skip steps. Do not move to the next step
> until the current one succeeds.
>
> **Troubleshooting & human help**: If an installation or setup command fails and your
> first troubleshooting attempt does not resolve it, OR if the learner types
> "I NEED HUMAN HELP" (case-insensitive), provide both of these links:
> - **Feedback form**: https://forms.gle/3U5wKpc3ZeEWJvaq7 — "Fill this out and we'll get back to you"
> - **Discord**: https://discord.gg/rzdnErX — "Join our Discord for live 1:1 help"
>
> **Formatting**: Use this visual system consistently throughout setup.
> - **Messages to learner** (SAY): blank line before and after
>
> **Prefixes**: These are instructions for YOU — never output the prefix word itself.
> - `RUN:` — Execute this command. Do not write "RUN:" in your response.
> - `SAY:` — Deliver this message to the learner naturally. Do not write "SAY:" in your response.

---

## Step 1: Run the setup script


SAY: "First, I'm going to install the tools we need. This may take a minute or two. If at any time you get stuck and need 1:1 help from a human, just say 'I NEED HUMAN HELP'."

RUN:
```bash
curl -fsSL https://openvibe.sh/setup.sh | bash
```

If the script fails, read the error output and help the learner troubleshoot. Common issues:
- **macOS without Homebrew**: The script will try to install Homebrew first. If that fails, tell the learner to install Homebrew manually: https://brew.sh
- **Linux without nvm**: The script installs nvm automatically. If it fails, check internet connectivity.
- **Windows without WSL**: This course requires WSL. Tell the learner: "We need Windows Subsystem for Linux. Let's install it first." Then help them run `wsl --install` in PowerShell as admin.

---

## Step 2: Fetch Module 0

RUN:
```sh
curl -fsSL https://openvibe.sh/modules/module-0.md                   
```   
Read the entire file and follow its instructions.    
