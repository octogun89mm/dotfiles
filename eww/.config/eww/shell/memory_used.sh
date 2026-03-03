#!/bin/bash
free --mebi | grep "Mem:" | awk '{printf "%.1f", $3/1024}'
