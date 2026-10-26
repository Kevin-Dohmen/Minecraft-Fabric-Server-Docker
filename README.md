# Minecraft Fabric Server (Docker)

Lightweight Docker setup for running a Minecraft Fabric server with Aikar's optimized JVM flags.

## Quick Start

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Adjust variables in `.env` if desired:
   - `MC_VERSION`: Minecraft version (e.g. `26.3`, `1.21.4`, `1.20.1`)
   - `FABRIC_LOADER_VERSION`: Fabric loader version (e.g. `0.20.1`)
   - `MIN_RAM` / `MAX_RAM`: RAM allocation (e.g. `2G` / `4G`)
   - `SERVER_PORT`: Host port mapping (default `25565`)

3. Build and launch:
   ```bash
   docker compose up -d --build
   ```

## Directory Structure
- `serverdata/`: Persistent server files (world, configs, mods, server.properties).
- `cache/`: Downloaded Fabric libraries and assets.
- `backups/`: Destination for world backups.
- `backup_world.sh`: Creates a zstd-compressed backup of the world.
- `cleanup_backups.sh`: Deletes old backups, keeping the most recent ones.

## Backups

Both scripts are run from the host (Linux, or Git Bash on Windows) and only need Docker.

```bash
./backup_world.sh
```

Writes `backups/<level-name>_<YYYY-MM-DD_HH-MM-SS>.tar.zst` and prints a summary (size, compression ratio, duration). If the server is running, the script pauses world saving over RCON (`save-off` / `save-all flush`) while the archive is written and resumes it afterwards, so the backup is consistent. If the server is stopped, it backs up from a temporary container. Set `ZSTD_LEVEL` (1-19, default 3) to trade speed for size.

RCON is enabled automatically by `server_start.sh`, with a random password stored in `server.properties`. The RCON port is not published to the host. You can also send console commands yourself:

```bash
docker compose exec fabric-server rcon list
```

```bash
./cleanup_backups.sh 10 --dry-run
```

Keeps the 10 most recent backups (default 5) and deletes the rest. Drop `--dry-run` to actually delete them.

To restore a backup, stop the server, move the current world folder aside, then extract:

```bash
docker compose run --rm -T fabric-server sh -c 'zstd -dc /backups/world_2026-10-26_14-30-05.tar.zst | tar -x -C /server'
```
