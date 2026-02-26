#!/usr/bin/env bash
# install.sh — sets up the Claude memory management system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$HOME/.claude/projects/-home-rabb1tl0ka/memory"
ST_DIR="$MEMORY_DIR/short-term"
GC_SCRIPT="$SCRIPT_DIR/memory-gc.sh"
INDEX_MD="$MEMORY_DIR/short-term-index.md"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo "Setting up memory management system..."

# 1. Create short-term directory
mkdir -p "$ST_DIR"
echo "✓ Created $ST_DIR"

# 2. Make GC script executable
chmod +x "$GC_SCRIPT"
echo "✓ GC script is executable"

# 3. Add cron job (daily at 8am)
CRON_JOB="0 8 * * * $GC_SCRIPT >> $HOME/.claude/memory-gc.log 2>&1"
if crontab -l 2>/dev/null | grep -qF "$GC_SCRIPT"; then
    echo "✓ Cron job already exists"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✓ Added cron job: daily at 8am"
fi

# 4. Update CLAUDE.md with memory management instructions
if grep -q "## Memory Management" "$CLAUDE_MD"; then
    echo "✓ CLAUDE.md already has memory management section"
else
    cat >> "$CLAUDE_MD" << 'EOF'

## Memory Management

Two-tier memory system — core (long-term) and short-term.

### When to use each:
- **"save as core memory"** → append directly to `MEMORY.md`
- **default "remember this"** → create a short-term file (expires in 30 days)
- Short-term = session fixes, one-off discoveries, not yet confirmed as durable
- Core = confirmed patterns, stable preferences, architectural decisions

### At session start:
Read `~/.claude/projects/-home-rabb1tl0ka/memory/short-term-index.md` if it exists.
When a topic from the index is relevant to the current task, read the full file
and increment its `accessed` counter.

### Creating a short-term memory:
1. File path: `~/.claude/projects/-home-rabb1tl0ka/memory/short-term/YYYY-MM-DD-slug.md`
2. Frontmatter:
```
---
created: YYYY-MM-DD
expires: YYYY-MM-DD
accessed: 0
tags: [tag1, tag2]
summary: One-line description
---
Content here...
```
3. Append a new entry to `short-term-index.md` (GC will rebuild on next run anyway)

### When reading a short-term file:
Increment the `accessed` field: `accessed: N` → `accessed: N+1`

### Promotion (handled automatically by GC daily at 8am):
- expired + accessed ≥ 3 → content appended to `MEMORY.md`, file deleted
- expired + accessed < 3 → file deleted
EOF
    echo "✓ Updated CLAUDE.md with memory management instructions"
fi

# 5. Create initial index if it doesn't exist
if [ ! -f "$INDEX_MD" ]; then
    cat > "$INDEX_MD" << 'EOF'
# Short-Term Memory Index
_Last GC run: never_

_No active short-term memories._
EOF
    echo "✓ Created initial short-term-index.md"
fi

echo ""
echo "Done. Run '$GC_SCRIPT' to test."
