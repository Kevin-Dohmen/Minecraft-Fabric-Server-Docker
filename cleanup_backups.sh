#!/bin/bash

# Configuration
BACKUP_DIR="./backups"
KEEP_COUNT=${1:-5} # Default to 5 if no argument is provided

# Ensure directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory $BACKUP_DIR does not exist. Nothing to clean."
    exit 0
fi

echo "Cleaning up backups in $BACKUP_DIR. Keeping the $KEEP_COUNT most recent files..."

# List files by modification time (newest first), then skip the first KEEP_COUNT files
# tail -n +X starts outputting from line X
FILES_TO_DELETE=$(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +$((KEEP_COUNT + 1)))

if [ -z "$FILES_TO_DELETE" ]; then
    echo "No old backups to delete (found $(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l) total)."
    exit 0
fi

# Count files to be deleted
DELETE_COUNT=$(echo "$FILES_TO_DELETE" | wc -l)
echo "Found $DELETE_COUNT old backups to purge."

for FILE in $FILES_TO_DELETE; do
    echo "Deleting: $FILE"
    rm "$FILE"
done

echo "Cleanup complete."
