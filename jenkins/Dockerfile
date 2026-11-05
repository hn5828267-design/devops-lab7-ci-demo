FROM maven:3.9.9-eclipse-temurin-21 AS maven
FROM jenkins/jenkins:lts-jdk21
COPY --from=maven /usr/share/maven /opt/maven
ENV MAVEN_HOME=/opt/maven
ENV PATH="/opt/maven/bin:${PATH}"
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
