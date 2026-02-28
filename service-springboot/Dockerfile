FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY service-springboot/pom.xml .
RUN mvn dependency:go-offline -B
COPY schemas /schemas
COPY service-springboot/src ./src
RUN mvn clean package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 11001
ENTRYPOINT ["java", "-jar", "app.jar"]
