# claude-mem-gc

A two-tier memory management system for Claude Code. Separates durable long-term memories from short-term ones, and automatically promotes or prunes them over time.

## The Problem

Claude Code's `MEMORY.md` grows unbounded. There's no concept of memory decay — everything gets equal permanence, and eventually the file becomes noisy and oversized.

## The Solution

Two tiers:

- **Core memory** (`MEMORY.md`) — stable, always loaded, manually curated
- **Short-term memory** (`short-term/*.md`) — temporary files with a 30-day expiry and an access counter

A daily cron job (the GC) processes expired short-term memories:
- **accessed ≥ 3** → promoted to `MEMORY.md` (it proved durable)
- **accessed < 3** → deleted (forgotten)

This mirrors how human memory consolidation works: things that keep coming up get encoded long-term, things that don't get dropped.

## Structure

```
~/.claude/projects/.../memory/
  MEMORY.md                  ← long-term, always auto-loaded by Claude Code
  short-term-index.md        ← one-liner index, rebuilt by GC on each run
  short-term/
    YYYY-MM-DD-slug.md       ← individual short-term memory files
```

### Short-term file format

```markdown
---
created: 2026-02-27
expires: 2026-03-29
accessed: 0
tags: [waybar, config]
summary: Fixed f048d icon — use literal UTF-8 char, not \u escape
---

## Topic

Details here...
```

## Installation

```bash
git clone git@github.com:rabb1tl0ka/claude-mem-gc.git
cd claude-mem-gc
bash install.sh
```

The install script:
1. Creates `memory/short-term/` directory
2. Makes `memory-gc.sh` executable
3. Adds a daily cron job at 8am
4. Appends memory management instructions to `~/.claude/CLAUDE.md`
5. Initializes `short-term-index.md`

## Usage

### From Claude's side

Claude is instructed (via `CLAUDE.md`) to:

- Read `short-term-index.md` at session start
- Load relevant short-term files and increment their `accessed` counter when reading
- Create short-term files for one-off discoveries
- Write directly to `MEMORY.md` when told **"save as core memory"**

### From your side

| What you say | What happens |
|---|---|
| "remember this" | Short-term file, 30-day expiry |
| "save as core memory" | Written directly to `MEMORY.md` |
| Nothing | GC handles promotion/deletion automatically |

## Running the GC manually

```bash
~/loka/code/claude-mem-gc/memory-gc.sh
```

Logs go to `~/.claude/memory-gc.log`.
