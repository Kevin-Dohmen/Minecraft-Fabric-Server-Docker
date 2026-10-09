# Minecraft Fabric Server (Docker)

Lightweight Docker setup for running a Minecraft Fabric server with Aikar's optimized JVM flags.

## Quick Start

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Adjust variables in `.env` if desired:
   - `MC_VERSION`: Minecraft version (e.g. `26.3`, `1.21.4`, `1.20.1`)
   - `FABRIC_LOADER_VERSION`: Fabric loader version (e.g. `0.19.5`)
   - `MIN_RAM` / `MAX_RAM`: RAM allocation (e.g. `2G` / `4G`)
   - `SERVER_PORT`: Host port mapping (default `25565`)

3. Build and launch:
   ```bash
   docker compose up -d --build
   ```

## Directory Structure
- `serverdata/`: Persistent server files (world, configs, mods, server.properties).
- `cache/`: Downloaded Fabric libraries and assets.
- `backups/`: Destination for automated world backups.
- `backup_world.sh`: Creates a tarball backup of the world.
- `cleanup_backups.sh`: Prunes backups older than 7 days.
