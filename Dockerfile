# Build stage: create the runnable jar with Maven (preferred) or Gradle if you use it
FROM eclipse-temurin:25-jdk AS build
WORKDIR /workspace

# Copy only build descriptors first for better layer caching
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw mvnw
RUN chmod +x mvnw && ./mvnw -q -Dmaven.test.skip=true dependency:go-offline

# Now copy the sources and build
COPY src src
RUN ./mvnw -q -DskipTests package

# Runtime stage: run the Spring Boot application on a slim JRE
FROM eclipse-temurin:25-jre
WORKDIR /app

# Configure a non-root user
RUN addgroup --system spring && adduser --system --ingroup spring spring
USER spring:spring

# Copy the fat jar from the build stage
COPY --from=build /workspace/target/*.jar /app/app.jar

# Expose default Spring Boot port
EXPOSE 8080

# JVM tuning for containers; adjustable via env
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=25.0"

# Pass active profile via SPRING_PROFILES_ACTIVE if needed (e.g., mysql, postgres)
ENTRYPOINT ["java","-jar","/app/app.jar"]
