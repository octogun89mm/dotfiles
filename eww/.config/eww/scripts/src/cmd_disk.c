#include "popen_util.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int cmd_disk(int argc, char **argv)
{
    const char *mount = (argc > 0) ? argv[0] : "/";

    char cmd[256];
    snprintf(cmd, sizeof(cmd), "df -BG '%s' 2>/dev/null", mount);

    char buf[512];
    if (popen_read(cmd, buf, sizeof(buf)) < 0) {
        printf("0/0G");
        return 0;
    }

    /* skip header line, parse second line */
    char *line = strchr(buf, '\n');
    if (!line) { printf("0/0G"); return 0; }
    line++;

    /* fields: Filesystem  1G-blocks  Used  Available  Use%  Mounted */
    char fs[128];
    long total_g = 0, used_g = 0;
    if (sscanf(line, "%s %ldG %ldG", fs, &total_g, &used_g) >= 3) {
        printf("%ld/%ldG", used_g, total_g);
    } else {
        printf("0/0G");
    }
    return 0;
}
