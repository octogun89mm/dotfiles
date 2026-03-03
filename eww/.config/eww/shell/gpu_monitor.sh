#!/bin/bash
# GPU stats via nvidia-smi, output as JSON for eww
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
  --format=csv,noheader,nounits | awk -F', ' '{
  printf "{\"usage\":\"%s\",\"vram_used\":\"%.1f\",\"vram_total\":\"%.1f\",\"temp\":\"%s\"}", $1, $2/1024, $3/1024, $4
}'
