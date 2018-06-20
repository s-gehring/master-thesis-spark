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
ENV SPARK_WORKER_PORT=5000
ENV SPARK_MASTER_WEBUI_PORT=8080
ENV SPARK_WORKER_WEBUI_PORT=8080

ENV SPARK_LOG_DIR="/spark/logs"
ENV SPARK_WORKER_DIR="/spark/work"

### Configure Spark

COPY spark-defaults.conf /spark/conf/spark-defaults.conf

### Expose ports.

# For Master
EXPOSE 7077
# For both WebUIs
EXPOSE 8080
# For Communication to Master
EXPOSE 5000
# For Cluster Manager WebUI
EXPOSE 4040
# For Cluster Manager History Server
EXPOSE 18080
# For Cluster Manager Executor
EXPOSE 5001
# For Cluster Manager Driver
EXPOSE 5002

### Add custom scripts.

COPY start-master-tailing.sh /start-master.sh
COPY start-slave-tailing.sh /start-slave.sh

### Healthcheck

HEALTHCHECK \
   --retries=2 \
   --timeout=5s \
   --interval=10s \
   CMD curl -f localhost:8080
