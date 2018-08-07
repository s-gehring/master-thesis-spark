#!/bin/bash

set -e

LOGS=/home/simon.gehring/master-logs/build


echo "Starting script. It is now $(date)."

echo "Deleting old logfiles..."
sudo rm -rf logs
mkdir logs
mkdir logs/build

echo "Building shared-uima-processor..."
cd ../master-thesis-program
mvn clean install \
1> ${LOGS}/shared-uima-processor.stdout.log \
2> ${LOGS}/shared-uima-processor.stderr.log

echo "Building shared-uima-benchmark..."
cd ../master-thesis-benchmark
mvn clean install \
1> ${LOGS}/shared-uima-benchmark.stdout.log \
2> ${LOGS}/shared-uima-benchmark.stderr.log

echo "Moving JAR file..."
cp target/shared-uima-benchmark-0.0.1-SNAPSHOT.jar ../master-thesis-spark/jars
cd ../master-thesis-spark

echo "Building shared-uima-processor Docker image..."
docker-compose -f compose-1m2s.yaml build \
1> ${LOGS}/shared-uima-processor-docker.stdout.log \
2> ${LOGS}/shared-uima-processor-docker.stderr.log

echo "Building UIMA-AS project..."
cd ../master-thesis-uimaas/LeoDeployment
mvn clean install \
1> ${LOGS}/shared-uima-as.stdout.log \
2> ${LOGS}/shared-uima-as.stderr.log

echo "Moving JAR file..."
cp target/shared-uima-as-0.0.1-SNAPSHOT.jar ../jars

echo "Building UIMA-AS Docker image..."
cd ..
docker-compose build \
1> ${LOGS}/uima-as-docker.stdout.log \
2> ${LOGS}/uima-as-docker.stderr.log

echo "Removing old containers (if applicable)."
cd ../master-thesis-spark
docker-compose -f compose-1m2s.yaml down --remove-orphans 1>logs/init-docker-compose-down.stdout.log \
2>logs/init-docker-compose-down.stderr.log


#echo "Starting benchmark with compression (logs at $COMPRESSION_LOGS, ${MEMORY_OF_SLAVE_MASTER:-12G} + ${NUMBER_OF_MACHINES}*${MEMORY_PER_MACHINE_IN_GB}G RAM and 1 + ${NUMBER_OF_MACHINES}*${CORES_PER_MACHINE} cores)"
#export SUP_COMPRESSION_ALGORITHM=gehring.uima.distributed.compression.ZLib
#export SUP_LOG_FILES=$COMPRESSION_LOGS
#docker-compose -f compose-1m2s.yaml up --scale slave-two=$NUMBER_OF_MACHINES -d 1>logs/compression-docker-compose-up.stdout.log \
#2>logs/compression-docker-compose-up.stderr.log

#echo "Successfully started benchmark. Wait for $TIMEOUT_HOURS hours..."
#countdown $TIMEOUT

#echo "Successfully waited (yay). Removing (hopefully) idling containers..."
#docker-compose -f compose-1m2s.yaml down 1>logs/compression-docker-compose-down.stdout.log \
#2>logs/compression-docker-compose-down.stderr.log

#echo "Removing useless JAR files..."
#sudo find logs -name \*.jar -delete

#echo "Starting benchmark without compression (logs at $NO_COMPRESSION_LOGS, ${MEMORY_OF_SLAVE_MASTER:-12G} + ${NUMBER_OF_MACHINES}*${MEMORY_PER_MACHINE_IN_GB}G RAM and 1 + ${NUMBER_OF_MACHINES}*${CORES_PER_MACHINE} cores)"
#export SUP_COMPRESSION_ALGORITHM=gehring.uima.distributed.compression.NoCompression
#export SUP_LOG_FILES=$NO_COMPRESSION_LOGS
#docker-compose -f compose-1m2s.yaml up --scale slave-two=$NUMBER_OF_MACHINES -d 1>logs/no-compression-docker-compose-up.stdout.log \
#2>logs/no-compression-docker-compose-up.stderr.log

#echo "Successfully started benchmark. Wait for $TIMEOUT_HOURS hours..."
#countdown $TIMEOUT

#echo "Successfully waited (yay). Removing (hopefully) idling containers..."
#docker-compose -f compose-1m2s.yaml down -v 1>logs/no-compression-docker-compose-down.stdout.log \
#2>logs/no-compression-docker-compose-down.stderr.log

#echo "Removing useless JAR files..."
#sudo find logs -name \*.jar -delete


#export SUP_LOG_FILES=$SINGLE_LOGS
#export SUP_SINGLE_INSTANCE=--single
#export MEMORY_OF_SLAVE_MASTER=$(($MEMORY_PER_MACHINE_IN_GB*$(($NUMBER_OF_MACHINES+1))))G
#export CORES_OF_SLAVE_MASTER=$(($CORES_PER_MACHINE*($NUMBER_OF_MACHINES+1)))
#echo "Starting benchmark single instance (Log files at $SINGLE_LOGS, $MEMORY_OF_SLAVE_MASTER memory, $CORES_OF_SLAVE_MASTER cores)"
#docker-compose -f compose-1m2s.yaml up --scale slave-two=0 -d 1>logs/single-docker-compose-up.stdout.log \
#2>logs/single-docker-compose-up.stderr.log

#echo "Successfully started benchmark. Wait for $TIMEOUT_HOURS hours..."
#countdown $TIMEOUT

#echo "Successfully waited (yay). Removing (hopefully) idling containers..."
#docker-compose -f compose-1m2s.yaml down 1>logs/single-docker-compose-down.stdout.log \
#2>logs/single-docker-compose-down.stderr.log


#echo "Retrieving log files..."
#export OLD_WD=$(pwd)
#cd logs/${COMPRESSION_LOGS}slave-one/workspace/driver*
#cp stdout $OLD_WD/logs/stdout-with-compression.log
#cp stderr $OLD_WD/logs/stderr-with-compression.log
#cd $OLD_WD
#cd logs/${NO_COMPRESSION_LOGS}slave-one/workspace/driver*
#cp stdout $OLD_WD/logs/stdout-without-compression.log
#cp stderr $OLD_WD/logs/stderr-without-compression.log
#cd $OLD_WD
#cd logs/${SINGLE_LOGS}slave-one/workspace/driver*
#cp stdout $OLD_WD/logs/stdout-single-instance.log
#cp stderr $OLD_WD/logs/stderr-single-instance.log
#cd $OLD_WD



#echo "Formatting files..."
#egrep -v "INFO|WARN" logs/stdout-with-compression.log > logs/stdout-with-compression.min.log
#egrep -v "INFO|WARN" logs/stderr-with-compression.log > logs/stderr-with-compression.min.log
#egrep -v "INFO|WARN" logs/stdout-without-compression.log > logs/stdout-without-compression.min.log
#egrep -v "INFO|WARN" logs/stderr-without-compression.log > logs/stderr-without-compression.min.log
#egrep -v "INFO|WARN" logs/stdout-single-instance.log > logs/stdout-single-instance.min.log
#egrep -v "INFO|WARN" logs/stderr-single-instance.log > logs/stderr-single-instance.min.log


echo "Done with the script. It is now $(date)."
