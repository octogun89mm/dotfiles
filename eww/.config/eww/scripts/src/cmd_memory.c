#include <stdio.h>
#include <string.h>

/* handles both memory-used and memory-total subcommands */

static int get_meminfo(unsigned long long *total_kb, unsigned long long *avail_kb)
{
    FILE *fp = fopen("/proc/meminfo", "r");
    if (!fp) return -1;

    char line[128];
    int got = 0;
    *total_kb = 0;
    *avail_kb = 0;

    while (fgets(line, sizeof(line), fp) && got < 2) {
        if (sscanf(line, "MemTotal: %llu kB", total_kb) == 1) got++;
        else if (sscanf(line, "MemAvailable: %llu kB", avail_kb) == 1) got++;
    }
    fclose(fp);
    return (got == 2) ? 0 : -1;
}

int cmd_memory_used(int argc, char **argv)
{
    (void)argc; (void)argv;

    unsigned long long total_kb, avail_kb;
    if (get_meminfo(&total_kb, &avail_kb) == 0) {
        double used_gb = (double)(total_kb - avail_kb) / 1048576.0;
        printf("%.1f", used_gb);
    } else {
        printf("0.0");
    }
    return 0;
}

int cmd_memory_total(int argc, char **argv)
{
    (void)argc; (void)argv;

    unsigned long long total_kb, avail_kb;
    if (get_meminfo(&total_kb, &avail_kb) == 0) {
        double total_gb = (double)total_kb / 1048576.0;
        printf("%.1f", total_gb);
    } else {
        printf("0.0");
    }
    return 0;
}
