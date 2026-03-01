#include "popen_util.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int cmd_gpu(int argc, char **argv)
{
    (void)argc; (void)argv;

    char buf[256];
    if (popen_read("nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu "
                   "--format=csv,noheader,nounits 2>/dev/null", buf, sizeof(buf)) < 0) {
        printf("{\"usage\":\"0\",\"vram_used\":\"0.0\",\"vram_total\":\"0.0\",\"temp\":\"0\"}");
        return 0;
    }

    int usage = 0, temp = 0;
    double vram_used = 0, vram_total = 0;

    /* format: "45, 1234, 8192, 65" */
    int mem_used_mib = 0, mem_total_mib = 0;
    if (sscanf(buf, "%d, %d, %d, %d", &usage, &mem_used_mib, &mem_total_mib, &temp) == 4) {
        vram_used = mem_used_mib / 1024.0;
        vram_total = mem_total_mib / 1024.0;
    }

    printf("{\"usage\":\"%d\",\"vram_used\":\"%.1f\",\"vram_total\":\"%.1f\",\"temp\":\"%d\"}",
           usage, vram_used, vram_total, temp);
    return 0;
}
