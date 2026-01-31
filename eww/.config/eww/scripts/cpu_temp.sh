#!/bin/bash
temp=$(cat /sys/class/thermal/thermal_zone3/temp)
echo $((temp / 1000))
