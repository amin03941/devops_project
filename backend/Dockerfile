FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY target/backend-1.0.0.jar app.jar
USER 10001:10001
EXPOSE 8081
ENTRYPOINT ["java", "-Xmx512m", "-jar", "/app/app.jar"]
