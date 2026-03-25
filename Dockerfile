FROM alpine:latest

RUN apk add --no-cache openjdk21-jre-headless
RUN apk add --no-cache curl
RUN apk add --no-cache eudev-dev

WORKDIR /opt/minecraft
RUN curl -o server.jar -L https://meta.fabricmc.net/v2/versions/loader/1.21.11/0.18.5/1.1.1/server/jar

COPY ./server_start.sh /opt/minecraft/server_start.sh
RUN chmod +x /opt/minecraft/server_start.sh

EXPOSE 25565

WORKDIR /server

CMD ["/opt/minecraft/server_start.sh"]
