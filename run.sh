#!/bin/bash


set -e

if [ -z "$TIMEOUT_HOURS" ]; then
  echo "No timeout specified. Defaulting to 6 hours."
  TIMEOUT_HOURS=6
else
  echo "Understood minimum filesize of $FILESIZE_MIN Bytes."
fi


if [ -z "$FILESIZE_MIN" ]; then
  echo "No minimum filesize specified."
else
  echo "Understood minimum filesize of $FILESIZE_MIN Bytes."
fi
if [ -z "$FILESIZE_MAX" ]; then
  echo "No maximum filesize specified."
else
  echo "Understood maximum filesize of $FILESIZE_MAX Bytes."
fi


TIMEOUT=$((60*60*$TIMEOUT_HOURS))


# Number of workers (+1, the master slave)
export NUMBER_OF_MACHINES=11

export MEMORY_PER_MACHINE_IN_GB=10

export CORES_PER_MACHINE=1

COMPRESSION_LOGS=with-compression/
NO_COMPRESSION_LOGS=without-compression/
SINGLE_LOGS=single-instance/
SUP_SINGLE_INSTANCE=

# Code for a console countdown timer (from https://superuser.com/questions/611538/is-there-a-way-to-display-a-countdown-or-stopwatch-timer-in-a-terminal/611582)
function countdown(){
   date1=$((`date +%s` + $1));
   while [ "$date1" -ge `date +%s` ]; do
     echo -ne "$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r";
     sleep 0.1
   done
}

echo "Starting script. It is now $(date)."


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


echo "Starting benchmark with compression (logs at $COMPRESSION_LOGS, ${MEMORY_OF_SLAVE_MASTER:-12G} + ${NUMBER_OF_MACHINES}*${MEMORY_PER_MACHINE_IN_GB}G RAM and 1 + ${NUMBER_OF_MACHINES}*${CORES_PER_MACHINE} cores)"
export SUP_COMPRESSION_ALGORITHM=gehring.uima.distributed.compression.ZLib
export SUP_LOG_FILES=$COMPRESSION_LOGS
docker-compose -f compose-1m2s.yaml up --scale slave-two=$NUMBER_OF_MACHINES -d 1>logs/compression-docker-compose-up.stdout.log \
2>logs/compression-docker-compose-up.stderr.log

echo "Successfully started benchmark. Wait for $TIMEOUT_HOURS hours..."
countdown $TIMEOUT

echo "Successfully waited (yay). Removing (hopefully) idling containers..."
docker-compose -f compose-1m2s.yaml down 1>logs/compression-docker-compose-down.stdout.log \
2>logs/compression-docker-compose-down.stderr.log

echo "Removing useless JAR files..."
sudo find logs -name \*.jar -delete

echo "Starting benchmark without compression (logs at $NO_COMPRESSION_LOGS, ${MEMORY_OF_SLAVE_MASTER:-12G} + ${NUMBER_OF_MACHINES}*${MEMORY_PER_MACHINE_IN_GB}G RAM and 1 + ${NUMBER_OF_MACHINES}*${CORES_PER_MACHINE} cores)"
export SUP_COMPRESSION_ALGORITHM=gehring.uima.distributed.compression.NoCompression
export SUP_LOG_FILES=$NO_COMPRESSION_LOGS
docker-compose -f compose-1m2s.yaml up --scale slave-two=$NUMBER_OF_MACHINES -d 1>logs/no-compression-docker-compose-up.stdout.log \
2>logs/no-compression-docker-compose-up.stderr.log

echo "Successfully started benchmark. Wait for $TIMEOUT_HOURS hours..."
countdown $TIMEOUT

echo "Successfully waited (yay). Removing (hopefully) idling containers..."
docker-compose -f compose-1m2s.yaml down -v 1>logs/no-compression-docker-compose-down.stdout.log \
2>logs/no-compression-docker-compose-down.stderr.log

echo "Removing useless JAR files..."
sudo find logs -name \*.jar -delete


export SUP_LOG_FILES=$SINGLE_LOGS
export SUP_SINGLE_INSTANCE=--single
export MEMORY_OF_SLAVE_MASTER=$(($MEMORY_PER_MACHINE_IN_GB*$(($NUMBER_OF_MACHINES+1))))G
export CORES_OF_SLAVE_MASTER=$(($CORES_PER_MACHINE*($NUMBER_OF_MACHINES+1)))
echo "Starting benchmark single instance (Log files at $SINGLE_LOGS, $MEMORY_OF_SLAVE_MASTER memory, $CORES_OF_SLAVE_MASTER cores)"
docker-compose -f compose-1m2s.yaml up --scale slave-two=0 -d 1>logs/single-docker-compose-up.stdout.log \
2>logs/single-docker-compose-up.stderr.log

echo "Successfully started benchmark. Wait for $TIMEOUT_HOURS hours..."
countdown $TIMEOUT

echo "Successfully waited (yay). Removing (hopefully) idling containers..."
docker-compose -f compose-1m2s.yaml down 1>logs/single-docker-compose-down.stdout.log \
2>logs/single-docker-compose-down.stderr.log


echo "Retrieving log files..."
export OLD_WD=$(pwd)
cd logs/${COMPRESSION_LOGS}slave-one/workspace/driver*
cp stdout $OLD_WD/logs/stdout-with-compression.log
cp stderr $OLD_WD/logs/stderr-with-compression.log
cd $OLD_WD
cd logs/${NO_COMPRESSION_LOGS}slave-one/workspace/driver*
cp stdout $OLD_WD/logs/stdout-without-compression.log
cp stderr $OLD_WD/logs/stderr-without-compression.log
cd $OLD_WD
cd logs/${SINGLE_LOGS}slave-one/workspace/driver*
cp stdout $OLD_WD/logs/stdout-single-instance.log
cp stderr $OLD_WD/logs/stderr-single-instance.log
cd $OLD_WD



echo "Formatting files..."
egrep -v "INFO|WARN" logs/stdout-with-compression.log > logs/stdout-with-compression.min.log
egrep -v "INFO|WARN" logs/stderr-with-compression.log > logs/stderr-with-compression.min.log
egrep -v "INFO|WARN" logs/stdout-without-compression.log > logs/stdout-without-compression.min.log
egrep -v "INFO|WARN" logs/stderr-without-compression.log > logs/stderr-without-compression.min.log
egrep -v "INFO|WARN" logs/stdout-single-instance.log > logs/stdout-single-instance.min.log
egrep -v "INFO|WARN" logs/stderr-single-instance.log > logs/stderr-single-instance.min.log


echo "Done with the script. It is now $(date)."
