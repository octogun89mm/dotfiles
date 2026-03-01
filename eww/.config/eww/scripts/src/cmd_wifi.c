#include "popen_util.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int cmd_wifi(int argc, char **argv)
{
    (void)argc; (void)argv;

    char buf[256];
    if (popen_read("nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null", buf, sizeof(buf)) > 0) {
        /* find line starting with * */
        char *line = buf;
        while (line) {
            if (line[0] == '*') {
                char *colon = strchr(line, ':');
                if (colon) {
                    char *end;
                    long sig = strtol(colon + 1, &end, 10);
                    if (end != colon + 1) {
                        printf("%ld", sig);
                        return 0;
                    }
                }
            }
            char *nl = strchr(line, '\n');
            line = nl ? nl + 1 : NULL;
        }
    }

    printf("0");
    return 0;
}
