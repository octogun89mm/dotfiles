#include <stdio.h>

int cmd_cpu_freq(int argc, char **argv)
{
    (void)argc; (void)argv;

    FILE *fp = fopen("/proc/cpuinfo", "r");
    if (!fp) { printf("0.00"); return 0; }

    char line[256];
    double sum = 0;
    int count = 0;

    while (fgets(line, sizeof(line), fp)) {
        double mhz;
        if (sscanf(line, "cpu MHz : %lf", &mhz) == 1) {
            sum += mhz;
            count++;
        }
    }
    fclose(fp);

    if (count > 0)
        printf("%.2f", sum / count / 1000.0);
    else
        printf("0.00");
    return 0;
}
