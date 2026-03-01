#include "popen_util.h"
#include "json_output.h"
#include <stdio.h>
#include <string.h>

int cmd_vpn(int argc, char **argv)
{
    (void)argc; (void)argv;

    char buf[512];
    if (popen_read_timeout("expressvpnctl status 2>/dev/null", buf, sizeof(buf), 1500) < 0 ||
        buf[0] == '\0') {
        printf("{\"status\":\"disconnected\",\"icon\":\"\xf3\xb0\x92\x99\",\"location\":\"\"}");
        return 0;
    }

    /* first line only */
    char *nl = strchr(buf, '\n');
    if (nl) *nl = '\0';

    if (strncmp(buf, "Connected to ", 13) == 0) {
        char esc_loc[256];
        json_escape(esc_loc, sizeof(esc_loc), buf + 13);
        printf("{\"status\":\"connected\",\"icon\":\"\xf3\xb0\x92\x98\",\"location\":\"%s\"}", esc_loc);
    } else {
        printf("{\"status\":\"disconnected\",\"icon\":\"\xf3\xb0\x92\x99\",\"location\":\"\"}");
    }
    return 0;
}
