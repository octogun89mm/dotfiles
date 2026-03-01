#include "proc_util.h"
#include <stdio.h>
#include <string.h>

#define INTERFACE "wlan1"
#define POLL_INTERVAL 2 /* must match defpoll interval */

static int net_speed(const char *direction)
{
    const char *stat_name;
    const char *state_prefix;

    if (strcmp(direction, "rx") == 0) {
        stat_name = "rx_bytes";
        state_prefix = "/tmp/rx_prev_eww_" INTERFACE;
    } else {
        stat_name = "tx_bytes";
        state_prefix = "/tmp/tx_prev_eww_" INTERFACE;
    }

    char sysfs_path[128];
    snprintf(sysfs_path, sizeof(sysfs_path),
             "/sys/class/net/" INTERFACE "/statistics/%s", stat_name);

    unsigned long long current;
    if (read_ull(sysfs_path, &current) != 0) {
        printf("00.00");
        return 0;
    }

    unsigned long long prev = current;
    FILE *sf = fopen(state_prefix, "r");
    if (sf) {
        if (fscanf(sf, "%llu", &prev) != 1)
            prev = current;
        fclose(sf);
    }

    sf = fopen(state_prefix, "w");
    if (sf) {
        fprintf(sf, "%llu", current);
        fclose(sf);
    }

    double speed = (double)(current - prev) / 1048576.0 / POLL_INTERVAL;
    printf("%05.2f", speed);
    return 0;
}

int cmd_download_speed(int argc, char **argv)
{
    (void)argc; (void)argv;
    return net_speed("rx");
}

int cmd_upload_speed(int argc, char **argv)
{
    (void)argc; (void)argv;
    return net_speed("tx");
}
