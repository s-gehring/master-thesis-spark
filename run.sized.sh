#!/bin/bash

set -e

KILOBYTE=1024
MEGABYTE=$(($KILOBYTE*1024))

sudo rm -rf logs_tiny
echo "------------- Benchmark from 1KB to 10KB ----------------"
FILESIZE_MIN=$KILOBYTE FILESIZE_MAX=$((10*$KILOBYTE)) ./run.sh
echo "---------------------- done -----------------------------"
mv logs logs_tiny

sudo rm -rf logs_small
echo "------------- Benchmark from 10KB to 100KB ----------------"
FILESIZE_MIN=$((10*$KILOBYTE)) FILESIZE_MAX=$((100*$KILOBYTE)) ./run.sh
echo "---------------------- done -----------------------------"
mv logs logs_small

sudo rm -rf logs_medium
echo "------------- Benchmark from 100KB to 1024KB ----------------"
FILESIZE_MIN=$((100*$KILOBYTE)) FILESIZE_MAX=$MEGABYTE ./run.sh
echo "---------------------- done -----------------------------"
mv logs logs_medium

sudo rm -rf logs_big
echo "------------- Benchmark from 1MB to 10MB ----------------"
FILESIZE_MIN=$MEGABYTE FILESIZE_MAX=$((10*$MEGABYTE)) ./run.sh
echo "---------------------- done -----------------------------"
mv logs logs_big

echo "Actually all benchmark done. Yay!"
