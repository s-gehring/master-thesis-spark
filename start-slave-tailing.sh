#!bin/bash

/spark/sbin/start-slave.sh "$@" && tail -f /spark/logs/*.out
