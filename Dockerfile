ARG JAVA_VERSION=25
FROM alpine:latest

ARG JAVA_VERSION
ARG MC_VERSION=26.3
ARG FABRIC_LOADER_VERSION=0.20.1
ARG FABRIC_INSTALLER_VERSION=1.1.2
ARG RCON_CLI_VERSION=1.7.7
ARG TARGETARCH

RUN apk add --no-cache openjdk${JAVA_VERSION}-jre-headless curl eudev-dev zstd

# RCON client, used by backup_world.sh to pause saving during backups
RUN curl -f -sSL "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_${TARGETARCH:-amd64}.tar.gz" \
    | tar -xz -C /usr/local/bin rcon-cli

WORKDIR /opt/minecraft

RUN curl -f -sSL -o server.jar \
    "https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar"

COPY ./server_start.sh /opt/minecraft/server_start.sh
COPY ./rcon.sh /usr/local/bin/rcon
RUN chmod +x /opt/minecraft/server_start.sh /usr/local/bin/rcon

EXPOSE 25565

WORKDIR /server

CMD ["/opt/minecraft/server_start.sh"]
