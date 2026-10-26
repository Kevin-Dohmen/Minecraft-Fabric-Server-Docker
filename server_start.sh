#!/bin/sh

# Auto-accept EULA on startup
echo "eula=true" > /server/eula.txt

# Enable RCON so backup_world.sh can pause saving during backups.
# The RCON port is not published to the host; a random password is
# generated on first start if server.properties doesn't set one.
PROPS=/server/server.properties

set_prop() {
    if grep -q "^$1=" "$PROPS" 2>/dev/null; then
        sed -i "s|^$1=.*|$1=$2|" "$PROPS"
    else
        echo "$1=$2" >> "$PROPS"
    fi
}

set_prop enable-rcon true
if ! grep -q '^rcon\.password=.' "$PROPS"; then
    set_prop rcon.password "$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"
fi

MIN_RAM="${MIN_RAM:-1G}"
MAX_RAM="${MAX_RAM:-4G}"

# exec so java replaces the shell as PID 1 and receives SIGTERM from
# `docker compose down`/`stop`, letting the server save the world before exiting
exec java \
    -Xms"${MIN_RAM}" \
    -Xmx"${MAX_RAM}" \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -jar /opt/minecraft/server.jar nogui
