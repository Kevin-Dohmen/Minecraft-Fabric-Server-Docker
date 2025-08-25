FROM alpine:latest

RUN apk add --no-cache openjdk21
RUN apk add --no-cache curl
RUN apk add --no-cache eudev-dev

WORKDIR /server

RUN curl -o server.jar -L https://meta.fabricmc.net/v2/versions/loader/1.21.1/0.17.2/1.1.0/server/jar

EXPOSE 25565

ENTRYPOINT ["java", "-Xmx4G", "-jar", "server.jar", "nogui"]
