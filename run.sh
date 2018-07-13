#!/bin/bash

set -e

TIMEOUT=$((10))
COMPRESSION_LOGS=with-compression/
NO_COMPRESSION_LOGS=without-compression/

# Code for a console countdown timer (from https://superuser.com/questions/611538/is-there-a-way-to-display-a-countdown-or-stopwatch-timer-in-a-terminal/611582)
function countdown(){
   date1=$((`date +%s` + $1));
   while [ "$date1" -ge `date +%s` ]; do
     echo -ne "$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r";
     sleep 0.1
   done
}

echo "Deleting old logfiles..."
sudo rm -rf logs
mkdir logs
mkdir logs/build




echo "Building shared-uima-processor..."
cd ../master-thesis-program
mvn clean install 1> ../master-thesis-spark/logs/build/shared-uima-processor.stdout.log \
2> ../master-thesis-spark/logs/build/shared-uima-processor.stderr.log

echo "Building shared-uima-benchmark..."
cd ../master-thesis-benchmark
mvn clean install 1> ../master-thesis-spark/logs/build/shared-uima-benchmark.stdout.log \
2> ../master-thesis-spark/logs/build/shared-uima-benchmark.stderr.log

echo "Moving JAR file..."
cp target/shared-uima-benchmark-0.0.1-SNAPSHOT.jar ../master-thesis-spark/jars
cd ../master-thesis-spark

echo "Removing old containers (if applicable)."
docker-compose -f compose-1m2s.yaml down --remove-orphans 1>logs/init-docker-compose-down.stdout.log \
2>logs/init-docker-compose-down.stderr.log

echo "Starting benchmark with compression..."
SUP_COMPRESSION_ALGORITHM=gehring.uima.distributed.compression.ZLib
SUP_LOG_FILES=$COMPRESSION_LOGS
docker-compose -f compose-1m2s.yaml up --scale slave-two=11 -d 1>logs/compression-docker-compose-up.stdout.log \
2>logs/compression-docker-compose-up.stderr.log

echo "Successfully started benchmark. Wait for 12 hours..."

countdown $TIMEOUT

echo "Successfully waited (yay). Removing (hopefully) idling containers..."
docker-compose -f compose-1m2s.yaml down 1>logs/compression-docker-compose-down.stdout.log \
2>logs/compression-docker-compose-down.stderr.log

echo "Removing useless JAR files..."
sudo find logs -name \*.jar -delete

echo "Starting benchmark without compression..."
SUP_COMPRESSION_ALGORITHM=gehring.uima.distributed.compression.NoCompression
SUP_LOG_FILES=$NO_COMPRESSION_LOGS
docker-compose -f compose-1m2s.yaml up --scale slave-two=11 -d 1>logs/no-compression-docker-compose-up.stdout.log \
2>logs/no-compression-docker-compose-up.stderr.log

echo "Successfully started benchmark. Wait for 12 hours..."
countdown $TIMEOUT

echo "Successfully waited (yay). Removing (hopefully) idling containers..."
docker-compose -f compose-1m2s.yaml down -v 1>logs/no-compression-docker-compose-down.stdout.log \
2>logs/no-compression-docker-compose-down.stderr.log

echo "Removing useless JAR files..."
sudo find logs -name \*.jar -delete

echo "Retrieving log files..."
OLD_WD=$(pwd)
cd $COMPRESSION_LOGS/slave-one/workspace/driver*
cp stdout $OLD_WD/logs/stdout-with-compression.log
cp stderr $OLD_WD/logs/stderr-with-compression.log
cd OLD_WD
cd $NO_COMPRESSION_LOGS/slave-one/workspace/driver*
cp stdout $OLD_WD/logs/stdout-without-compression.log
cp stderr $OLD_WD/logs/stderr-without-compression.log
cd $OLD_WD

echo "Formatting files..."
egrep -v "INFO|WARN" logs/stdout-with-compression.log > logs/stdout-with-compression.min.log
egrep -v "INFO|WARN" logs/stderr-with-compression.log > logs/stderr-with-compression.min.log
egrep -v "INFO|WARN" logs/stdout-without-compression.log > logs/stdout-without-compression.min.log
egrep -v "INFO|WARN" logs/stderr-without-compression.log > logs/stderr-without-compression.min.log

echo "Done c:"
