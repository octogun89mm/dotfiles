#include "popen_util.h"
#include "signal_handler.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void get_volume(void)
{
    char vol_buf[64], mute_buf[64];

    if (popen_read("pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null", vol_buf, sizeof(vol_buf)) < 0)
        vol_buf[0] = '\0';
    if (popen_read("pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null", mute_buf, sizeof(mute_buf)) < 0)
        mute_buf[0] = '\0';

    /* parse volume: find first number followed by % */
    int vol = 0;
    char *p = vol_buf;
    while (*p) {
        if (*p >= '0' && *p <= '9') {
            char *end;
            long v = strtol(p, &end, 10);
            if (*end == '%') { vol = (int)v; break; }
            p = end;
        } else {
            p++;
        }
    }

    int muted = (strstr(mute_buf, "yes") != NULL);

    const char *icon;
    if (muted) icon = "\xf3\xb0\x96\x81";       /* 󰖁 */
    else if (vol >= 66) icon = "\xf3\xb0\x95\xbe"; /* 󰕾 */
    else if (vol >= 33) icon = "\xf3\xb0\x96\x80"; /* 󰖀 */
    else icon = "\xf3\xb0\x95\xbf";                /* 󰕿 */

    printf("{\"volume\":%d,\"muted\":%s,\"icon\":\"%s\"}\n",
           vol, muted ? "true" : "false", icon);
    fflush(stdout);
}

static void on_pactl_line(const char *line, void *ctx)
{
    (void)ctx;
    if (strstr(line, "sink") || strstr(line, "server"))
        get_volume();
}

int cmd_volume(int argc, char **argv)
{
    (void)argc; (void)argv;
    signal_setup();

    get_volume();

    popen_stream("pactl subscribe 2>/dev/null", on_pactl_line, NULL, NULL);
    return 0;
}
