#!/bin/bash

# Configuration
WORLD_DIR="./serverdata/world"
BACKUP_DIR="./backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Get today's date in YYYY-MM-DD format
DATE=$(date +%Y-%m-%d)

# Find the next number for today by finding the highest existing suffix
LATEST_NUM=$(ls "$BACKUP_DIR"/${DATE}_*.tar.gz 2>/dev/null | sed -E "s/.*_([0-9]+)\.tar\.gz/\1/" | sort -n | tail -1)
if [ -z "$LATEST_NUM" ]; then
    NEXT_NUM=1
else
    NEXT_NUM=$((LATEST_NUM + 1))
fi

# Format filename: [date]_[number].tar.gz
FILENAME="${DATE}_${NEXT_NUM}.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$FILENAME"

echo "Starting backup of $WORLD_DIR to $BACKUP_PATH..."

# Check if world directory exists
if [ ! -d "$WORLD_DIR" ]; then
    echo "Error: World directory $WORLD_DIR does not exist."
    exit 1
fi

# Create compressed backup
# -C changes to the parent directory to avoid including the whole path in the tar
tar -czf "$BACKUP_PATH" -C "$(dirname "$WORLD_DIR")" "$(basename "$WORLD_DIR")"

if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_PATH"
else
    echo "Backup failed!"
    exit 1
fi
