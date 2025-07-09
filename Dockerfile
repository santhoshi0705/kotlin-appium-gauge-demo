# ---------- Stage 1: Build project dependencies ----------
FROM maven:3.8.7-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy Maven config and preload dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source code
COPY . .

# Build and validate Gauge specs (skip tests here)
RUN mvn validate


# ---------- Stage 2: Runtime (with Gauge & Appium dependencies) ----------
FROM eclipse-temurin:17-jdk

# Install dependencies: Node, npm, Gauge, Appium
RUN apt-get update && apt-get install -y curl unzip wget gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g appium && \
    npm install -g appium-doctor && \
    npm install -g appium@next # Optional: get latest Appium 2.x CLI

# Install Gauge
RUN curl -SsL https://downloads.gauge.org/stable | sh

# Install Gauge Java plugin (for Kotlin/Java tests)
RUN gauge install java

# Optional: install other Gauge plugins
# RUN gauge install html-report

# Create app directory
WORKDIR /app

# Copy compiled project
COPY --from=builder /app .

# Default command to run specs
CMD ["gauge", "run", "specs/"]
