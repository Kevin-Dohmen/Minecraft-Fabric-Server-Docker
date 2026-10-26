#!/usr/bin/env bash

# Back up the world to ./backups/<level-name>_<YYYY-MM-DD_HH-MM-SS>.tar.zst
#
# tar and zstd run inside the server image, so the host only needs Docker.
# If the server is running, saving is paused over RCON (save-off + save-all flush)
# while the archive is written, so region files don't change mid-copy.
#
# Usage: ./backup_world.sh   (set ZSTD_LEVEL=1..19 to trade speed for size, default 3)

set -euo pipefail
cd "$(dirname "$0")"

# Configuration
SERVICE="fabric-server"
BACKUP_DIR="./backups"
ZSTD_LEVEL="${ZSTD_LEVEL:-3}"

# Stop Git Bash on Windows from rewriting /backups etc. into Windows paths
export MSYS_NO_PATHCONV=1

log() { echo "[$(date +%H:%M:%S)] $*"; }
die() { log "Error: $*" >&2; exit 1; }

# Format a size in KiB as e.g. "1.2 GB"
human() { awk -v k="$1" 'BEGIN { split("KB MB GB TB", u); i = 1; while (k >= 1024 && i < 4) { k /= 1024; i++ } printf "%.1f %s", k, u[i] }'; }

if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
else
    die "Docker Compose not found."
fi
docker info >/dev/null 2>&1 || die "Docker is not running."

# The world folder is named by level-name in server.properties
LEVEL=$(sed -n 's/^level-name=//p' serverdata/server.properties 2>/dev/null | tr -d '\r')
LEVEL="${LEVEL:-world}"
[ -d "serverdata/$LEVEL" ] || die "World directory serverdata/$LEVEL does not exist."

mkdir -p "$BACKUP_DIR"
FILENAME="${LEVEL}_$(date +%Y-%m-%d_%H-%M-%S).tar.zst"

SOURCE_KB=$(du -sk "serverdata/$LEVEL" | cut -f1)
SOURCE_FILES=$(find "serverdata/$LEVEL" -type f | wc -l)

rcon() { "${COMPOSE[@]}" exec -T "$SERVICE" rcon "$@" >/dev/null; }

SAVING_PAUSED=0
resume_saving() {
    [ "$SAVING_PAUSED" -eq 1 ] || return 0
    if rcon save-on; then
        SAVING_PAUSED=0
        log "World saving resumed after $((SECONDS - PAUSED_AT))s."
    else
        log "Warning: could not re-enable saving. Run: docker compose exec $SERVICE rcon save-on" >&2
    fi
}
trap resume_saving EXIT

if [ -n "$("${COMPOSE[@]}" ps --status running -q "$SERVICE" 2>/dev/null)" ]; then
    MODE="live"
    log "Server is running. Pausing world saving over RCON..."
    rcon say "Starting world backup..." \
        || die "Could not reach the server over RCON. If it was started before this update, restart it once; otherwise wait until it has finished starting."
    PAUSED_AT=$SECONDS
    SAVING_PAUSED=1
    rcon save-off
    rcon save-all flush
    RUN=(exec -T "$SERVICE")
else
    MODE="offline"
    log "Server is not running. Backing up from a temporary container..."
    RUN=(run --rm --no-deps -T "$SERVICE")
fi

log "Archiving serverdata/$LEVEL ($(human "$SOURCE_KB"), $SOURCE_FILES files) -> $BACKUP_DIR/$FILENAME"

# Write to .partial and rename on success, so an interrupted backup never looks complete
# shellcheck disable=SC2016
"${COMPOSE[@]}" "${RUN[@]}" sh -c '
    set -eo pipefail
    tar -cf - -C /server "$1" | zstd -q -T0 -"$3" -o "/backups/$2.partial" \
        || { rm -f "/backups/$2.partial"; exit 1; }
    mv "/backups/$2.partial" "/backups/$2"
' sh "$LEVEL" "$FILENAME" "$ZSTD_LEVEL" || die "Archiving failed."

resume_saving
if [ "$MODE" = "live" ]; then rcon say "World backup complete." || true; fi

ARCHIVE_KB=$(du -sk "$BACKUP_DIR/$FILENAME" | cut -f1)
BACKUP_COUNT=$(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name '*.tar.zst' -o -name '*.tar.gz' \) | wc -l)
BACKUP_TOTAL_KB=$(du -sk "$BACKUP_DIR" | cut -f1)

echo
echo "Backup complete"
echo "  File:     $BACKUP_DIR/$FILENAME"
echo "  World:    $LEVEL ($(human "$SOURCE_KB"), $SOURCE_FILES files)"
echo "  Archive:  $(human "$ARCHIVE_KB") ($((ARCHIVE_KB * 100 / (SOURCE_KB > 0 ? SOURCE_KB : 1)))% of original, zstd -$ZSTD_LEVEL)"
echo "  Mode:     $MODE"
echo "  Took:     ${SECONDS}s"
echo "  Backups:  $BACKUP_COUNT in $BACKUP_DIR ($(human "$BACKUP_TOTAL_KB") total)"
