#include "proc_util.h"
#include <stdio.h>

int cmd_cpu_temp(int argc, char **argv)
{
    (void)argc; (void)argv;

    unsigned long long temp;
    if (read_ull("/sys/class/thermal/thermal_zone3/temp", &temp) == 0)
        printf("%llu", temp / 1000);
    else
        printf("0");
    return 0;
}
