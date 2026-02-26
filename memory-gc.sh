#!/usr/bin/env bash
# memory-gc.sh — Claude memory garbage collector
# Prunes expired short-term memories, promotes durable ones to MEMORY.md

set -euo pipefail

MEMORY_DIR="$HOME/.claude/projects/-home-rabb1tl0ka/memory"
ST_DIR="$MEMORY_DIR/short-term"
MEMORY_MD="$MEMORY_DIR/MEMORY.md"
INDEX_MD="$MEMORY_DIR/short-term-index.md"
TODAY=$(date +%Y-%m-%d)
PROMOTE_THRESHOLD=3

mkdir -p "$ST_DIR"

promoted=0
deleted=0
active=0

shopt -s nullglob

for file in "$ST_DIR"/*.md; do
    expires=$(grep "^expires:" "$file" | awk '{print $2}')
    accessed=$(grep "^accessed:" "$file" | awk '{print $2}')

    [[ -z "$expires" ]] && continue

    if [[ "$expires" < "$TODAY" || "$expires" == "$TODAY" ]]; then
        if [[ "${accessed:-0}" -ge "$PROMOTE_THRESHOLD" ]]; then
            # Promote: extract content after the closing --- of frontmatter
            printf "\n" >> "$MEMORY_MD"
            awk 'BEGIN{count=0} /^---/{count++; next} count>=2{print}' "$file" >> "$MEMORY_MD"
            echo "Promoted: $(basename "$file")"
            promoted=$((promoted + 1))
        else
            echo "Deleted: $(basename "$file") (accessed: ${accessed:-0})"
            deleted=$((deleted + 1))
        fi
        rm "$file"
    fi
done

# Rebuild short-term index
{
    echo "# Short-Term Memory Index"
    echo "_Last GC run: $(date '+%Y-%m-%d %H:%M')_"
    echo ""

    for file in "$ST_DIR"/*.md; do
        expires=$(grep "^expires:" "$file" | awk '{print $2}')
        accessed=$(grep "^accessed:" "$file" | awk '{print $2}')
        tags=$(grep "^tags:" "$file" | sed 's/^tags: *//')
        summary=$(grep "^summary:" "$file" | sed 's/^summary: *//')

        echo "- **$(basename "$file")** | expires: $expires | accessed: ${accessed:-0} | $tags"
        echo "  → $summary"
        echo ""
        active=$((active + 1))
    done

    [[ $active -eq 0 ]] && echo "_No active short-term memories._"
} > "$INDEX_MD"

echo "GC complete — promoted: $promoted, deleted: $deleted, active: $active"
