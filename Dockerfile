# ----- builder -----
FROM maven:3.9.8-eclipse-temurin-11 AS builder
WORKDIR /usr/src/easybuggy
COPY . .
RUN mvn -B package

# ----- runtime -----
FROM eclipse-temurin:11-jre-jammy
WORKDIR /app
# if your build outputs target/ROOT.war, copy that; otherwise adjust the name
COPY --from=builder /usr/src/easybuggy/target/ROOT.war /app/ROOT.war
# example startup (Tomcat/Jetty/etc. as appropriate) — or keep whatever you had
