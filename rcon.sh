#!/bin/sh

# Send a console command to the server over RCON, using the port and password
# from server.properties. Usage: docker compose exec fabric-server rcon list

PROPS=/server/server.properties

prop() { sed -n "s/^$1=//p" "$PROPS" | tr -d '\r'; }

PORT="$(prop rcon.port)"

exec rcon-cli --host 127.0.0.1 --port "${PORT:-25575}" --password "$(prop rcon.password)" "$@"
