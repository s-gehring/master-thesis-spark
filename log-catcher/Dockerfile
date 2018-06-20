FROM openjdk:8

COPY target/log-catcher-*.jar /log-catcher.jar

EXPOSE 8080

CMD ["java", "-jar", "/log-catcher.jar"]

HEALTHCHECK \
   --retries=2 \
   --timeout=5s \
   --interval=10s \
   CMD curl -f localhost:8080/ping
