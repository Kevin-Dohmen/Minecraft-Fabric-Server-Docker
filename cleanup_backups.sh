#!/usr/bin/env bash

# Delete old world backups, keeping the KEEP_COUNT most recent (default 5).
# Usage: ./cleanup_backups.sh [KEEP_COUNT] [--dry-run]

set -euo pipefail
cd "$(dirname "$0")"

# Configuration
BACKUP_DIR="./backups"
KEEP_COUNT=5
DRY_RUN=0

usage() { echo "Usage: $0 [KEEP_COUNT] [--dry-run]" >&2; exit 1; }

# Format a size in KiB as e.g. "1.2 GB"
human() { awk -v k="$1" 'BEGIN { split("KB MB GB TB", u); i = 1; while (k >= 1024 && i < 4) { k /= 1024; i++ } printf "%.1f %s", k, u[i] }'; }

for ARG in "$@"; do
    case "$ARG" in
        -n|--dry-run) DRY_RUN=1 ;;
        ''|*[!0-9]*) usage ;;
        *) KEEP_COUNT=$((10#$ARG)) ;;
    esac
done

if [ "$KEEP_COUNT" -lt 1 ]; then
    echo "KEEP_COUNT must be at least 1." >&2
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory $BACKUP_DIR does not exist. Nothing to clean."
    exit 0
fi

# Finished backups only (in-progress ones end in .partial), newest first by modification time
BACKUPS=()
while IFS= read -r FILE; do
    BACKUPS+=("$FILE")
done < <(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name '*.tar.zst' -o -name '*.tar.gz' \) -printf '%T@\t%p\n' \
    | sort -rn | cut -f2-)

TOTAL=${#BACKUPS[@]}
if [ "$TOTAL" -le "$KEEP_COUNT" ]; then
    echo "Found $TOTAL backups in $BACKUP_DIR; keeping up to $KEEP_COUNT. Nothing to delete."
    exit 0
fi

[ "$DRY_RUN" -eq 1 ] && ACTION="Would delete" || ACTION="Deleting"
echo "Found $TOTAL backups in $BACKUP_DIR; keeping the $KEEP_COUNT most recent."

FREED_KB=0
for FILE in "${BACKUPS[@]:KEEP_COUNT}"; do
    SIZE_KB=$(du -sk "$FILE" | cut -f1)
    FREED_KB=$((FREED_KB + SIZE_KB))
    echo "  $ACTION: $FILE ($(human "$SIZE_KB"))"
    [ "$DRY_RUN" -eq 1 ] || rm -- "$FILE"
done

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: $((TOTAL - KEEP_COUNT)) backups ($(human "$FREED_KB")) would be deleted."
else
    echo "Deleted $((TOTAL - KEEP_COUNT)) backups, freed $(human "$FREED_KB")."
fi
