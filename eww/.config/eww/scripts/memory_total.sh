#!/bin/bash
free --mebi | grep "Mem:" | awk '{printf "%.1f", $2/1024}'
