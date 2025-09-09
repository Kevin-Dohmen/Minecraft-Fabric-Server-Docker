FROM openjdk:26-jdk-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /server

RUN curl -o server.jar -L https://meta.fabricmc.net/v2/versions/loader/1.21.8/0.17.2/1.1.0/server/jar

EXPOSE 25565

ENTRYPOINT ["java", "-Xmx4G", "-jar", "server.jar", "nogui"]
