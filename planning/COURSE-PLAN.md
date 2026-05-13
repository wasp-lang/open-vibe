# Open Vibe — Course Plan

## Concept
An async, AI-led course where learners use an AI coding agent as their tutor and pair programmer to learn web dev by building real things with Wasp. Delivered as a multi-page LLMs.txt website — learners point their agent at a module URL and the AI guides them through it interactively.

## Audience
- Complete beginners (never written code)
- Adjacent-technical folks (designers, PMs, marketers who've dabbled)
- Non-technical founders who want to build an MVP

## Three-Phase Arc

| Phase | What they build | Template | Status |
|-------|----------------|----------|--------|
| **1 (MVP)** | Explore & extend a full-featured todo app | `wasp new` (default) | Building now |
| **2** | Design & build their own custom web app | `wasp new` (from scratch) | Future |
| **3** | Build a functioning SaaS product | `wasp new -t saas` (Open SaaS) | Future |

## Delivery

- **Primary**: Multi-page LLMs.txt site (one URL per module), following the standard llms.txt convention
- **Supplement**: Short YouTube videos per module (~5-10 min) — marketing/motivation layer, not the main learning
- **Error recovery**: Claude diagnoses + explains errors; git branch checkpoints per module for resets
- **1:1 help**: Funnel to Kenny for live support (link in YT descriptions)

## Teaching Approach

- **80%+ vibe-coding** — learners direct Claude, understand output, learn by doing
- **Claude switches modes**: `[TUTOR MODE]` for concepts, `[PAIR PROGRAMMER MODE]` for building
- **Prompting woven in**: no separate "how to prompt" module — every lesson models good AI collaboration
- **Module flow**: Explore existing code → Modify something small → Extend with a new feature
- **Start with building, not theory**: jump into the app immediately, weave in concepts as they arise

## LLMs.txt Site Structure

```
site.com/
├── llms.txt                    # Index: links to all modules
├── module-0.md                 # Setup & First Vibe
├── module-1.md                 # Data & The Database
├── module-2.md                 # Making It Look Good
└── module-3.md                 # How It All Connects
```

Each module is a standalone markdown file that Claude fetches and follows.

## Learner Workflow

1. Install Wasp + an AI coding agent
2. Run `git clone https://github.com/wasp-lang/ship-your-first-app-starter.git my-first-app && cd my-first-app`
3. Open their AI coding agent and tell it to fetch: `https://openvibe.sh/llms.txt`
   - If the agent can't fetch URLs: `curl -fsSL <url> -o <filename>.md` and point the agent at the local file
4. The agent fetches the page, reads the instructions, becomes their tutor
5. At the end of each module, the agent verifies understanding and points to the next module
6. If things break: `git checkout module-X-complete` to reset to a known-good state

---

## Authoring Notes

- **Always use `wasp db migrate-dev --name <descriptive-name>`** (not bare `wasp db migrate-dev`). The interactive migration-name prompt hangs in most AI coding agents since they can't handle interactive input. The `--name` flag passes the name directly.
- **Progress tracking**: Every module's Meta block must include the `**Progress tracking**` instruction. The agent writes `public/course-progress.json` (`{ "module": N, "beat": N, "title": "...", "status": "in-progress" | "complete" }`) and prints a `[■■□□]` progress bar. Progress is updated at the *start* of each new beat (not the end of the previous one) via a `MUST DO` directive — this avoids inconsistencies if the session drops mid-beat.
- **"Continue" command**: Every module's Meta block must include the `**"Continue"**` instruction, which tells the agent to advance to the next step/beat when the learner types "continue".
- **Side-by-side windows**: When `wasp start` runs for the first time, suggest the learner arrange their terminal and browser side by side.

---

## Phase 1 Modules

### Module 0: Setup & First Vibe
- Install tools, clone the starter app, start the app
- First interaction with AI tutor — high-level overview of what a web app is
- **Explore**: The three layers (frontend, backend, database) conceptually — no file contents
- **Modify**: Change something visible (app title, color) via prompting
- *Concepts*: What a web app is, how the frontend/backend/database loop works, what Wasp/React/Prisma are
- *Prompting focus*: How to give the agent context, how to describe what you want

### Module 1: Data & The Database
- **Explore**: The actual project files — walk through `main.wasp`, `schema.prisma`, and `src/` to see how the three layers map to real code. Then dive into the data model — how tasks are stored
- **Modify**: Add a field to tasks (priority, due date)
- **Extend**: Build a feature using the new field (filter/sort)
- *Concepts*: Reading code with AI help, what a database schema is, CRUD, data flow from DB → server → client
- *Prompting focus*: How to describe features you want, reviewing the agent's plan before it codes

### Module 2: Making It Look Good
- **Explore**: Existing UI, components, Tailwind classes, HTML structure
- **Modify**: Restyle the todo list — layout, colors, spacing
- **Extend**: Build a new UI component (dashboard, tag system, etc.)
- *Concepts*: HTML elements, CSS/Tailwind basics, component thinking
- *Prompting focus*: How to describe visual changes to AI, iterating on design

### Module 3: How It All Connects
- **Explore**: Trace a request end-to-end: click → browser → server → DB → back
- **Modify**: Add a new API operation (bulk-complete, search)
- **Extend**: Build a feature tying it all together (task sharing, notifications)
- *Concepts*: HTTP, client-server model, APIs, auth basics (what Wasp handles for you)
- *Prompting focus*: Asking Claude to explain complex flows, debugging together

---

## Next Steps

1. **Finalize the module template format** (see `MODULE-TEMPLATE.md`)
2. **Write Module 0** as a proof of concept
3. **Test Module 0** with AI coding agents — does it actually work well as a tutor?
4. **Record a pilot YT video** for Module 0
5. **Get 3-5 beta testers** (actual beginners) to try it
6. **Iterate**, then build Modules 1-3
7. **Decide on domain/hosting** once content is validated
