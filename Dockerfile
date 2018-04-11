FROM openjdk:8

### Install Scala.

ADD scala-*.tgz /scala/
RUN mv /scala/scala-*/* /scala/
RUN rm -rf /scala/scala-*

RUN chmod -R 0777 /scala
RUN cp /scala/bin/* /bin/
RUN cp /scala/lib/* /lib/

ENV SCALA_HOME=/scala

### Install Spark.

ADD spark-*-bin-hadoop2.7.tgz /spark
RUN mv /spark/spark-*-bin-hadoop2.7/* /spark/
RUN rm -rf /spark/spark-*-bin-hadoop2.7

ENV PATH="${PATH}:/spark/bin"

### Expose ports.

# For Master
EXPOSE 7077
# For Master WebUI
EXPOSE 8080
# For Slave WebUI
EXPOSE 8081

### Add custom scripts.

COPY start-master-tailing.sh /start-master.sh
COPY start-slave-tailing.sh /start-slave.sh

### Healthcheck
# Disabled, since spark doesn't always provide the UI
# at the same ports. The healthcheck should be
# done on docker-compose level.

# HEALTHCHECK \
#   --retries=2 \
#   --timeout=5s \
#   --interval=10s \
#   curl -f localhost:8080 || curl -f localhost:8081
