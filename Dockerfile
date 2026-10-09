ARG JAVA_VERSION=25
FROM alpine:latest

ARG JAVA_VERSION
ARG MC_VERSION=26.3
ARG FABRIC_LOADER_VERSION=0.19.5
ARG FABRIC_INSTALLER_VERSION=1.1.2

RUN apk add --no-cache openjdk${JAVA_VERSION}-jre-headless curl eudev-dev

WORKDIR /opt/minecraft

RUN curl -f -sSL -o server.jar \
    "https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar"

COPY ./server_start.sh /opt/minecraft/server_start.sh
RUN chmod +x /opt/minecraft/server_start.sh

EXPOSE 25565

WORKDIR /server

CMD ["/opt/minecraft/server_start.sh"]
