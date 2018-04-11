#!bin/bash

/spark/sbin/start-master.sh "$@" && tail -f /spark/logs/*.out
