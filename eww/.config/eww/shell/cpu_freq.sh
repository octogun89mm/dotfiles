#!/bin/bash
grep "cpu MHz" /proc/cpuinfo | awk '{sum+=$4; count++} END {printf "%.2f", sum/count/1000}'
