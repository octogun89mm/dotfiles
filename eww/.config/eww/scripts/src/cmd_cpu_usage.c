#include "proc_util.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int cmd_cpu_usage(int argc, char **argv)
{
    (void)argc; (void)argv;

    FILE *fp = fopen("/proc/stat", "r");
    if (!fp) { printf("0"); return 0; }

    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
    char cpu[8];
    if (fscanf(fp, "%s %llu %llu %llu %llu %llu %llu %llu %llu",
               cpu, &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal) != 9) {
        fclose(fp);
        printf("0");
        return 0;
    }
    fclose(fp);

    unsigned long long total = user + nice + system + idle + iowait + irq + softirq + steal;

    const char *state_file = "/tmp/eww_cpu_prev";
    unsigned long long prev_total = 0, prev_idle = 0;
    int have_prev = 0;

    FILE *sf = fopen(state_file, "r");
    if (sf) {
        if (fscanf(sf, "%llu %llu", &prev_total, &prev_idle) == 2)
            have_prev = 1;
        fclose(sf);
    }

    sf = fopen(state_file, "w");
    if (sf) {
        fprintf(sf, "%llu %llu", total, idle);
        fclose(sf);
    }

    int usage = 0;
    if (have_prev) {
        unsigned long long diff_total = total - prev_total;
        unsigned long long diff_idle = idle - prev_idle;
        if (diff_total > 0)
            usage = (int)((diff_total - diff_idle) * 100 / diff_total);
    }

    printf("%d", usage);
    return 0;
}
