FROM alpine:latest

RUN apk add --no-cache openjdk21-jre-headless
RUN apk add --no-cache curl
RUN apk add --no-cache eudev-dev

WORKDIR /server

RUN curl -o server.jar -L https://meta.fabricmc.net/v2/versions/loader/1.21.4/0.16.14/1.0.1/server/jar

COPY ./server_start.sh /server/server_start.sh
RUN chmod +x /server/server_start.sh

EXPOSE 25565

CMD ["/server/server_start.sh"]
