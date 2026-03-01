#include "popen_util.h"
#include "json_output.h"
#include "signal_handler.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void copy_bounded(char *dst, size_t dstlen, const char *src)
{
    size_t n;

    if (!dst || dstlen == 0) return;
    if (!src) {
        dst[0] = '\0';
        return;
    }

    n = strlen(src);
    if (n >= dstlen) n = dstlen - 1;
    memcpy(dst, src, n);
    dst[n] = '\0';
}

static void query_mpd(void)
{
    char current[1024], status_buf[2048];

    if (popen_read("mpc -f '%artist%\\t%title%' current 2>/dev/null", current, sizeof(current)) < 0)
        current[0] = '\0';
    if (popen_read("mpc status 2>/dev/null", status_buf, sizeof(status_buf)) < 0)
        status_buf[0] = '\0';

    /* parse artist/title from current */
    char artist[512] = "", title[512] = "";
    char *tab = strchr(current, '\t');
    if (tab) {
        *tab = '\0';
        copy_bounded(artist, sizeof(artist), current);
        copy_bounded(title, sizeof(title), tab + 1);
    } else if (current[0]) {
        copy_bounded(title, sizeof(title), current);
    }

    /* parse state */
    const char *state = "stopped";
    if (strstr(status_buf, "[playing]")) state = "playing";
    else if (strstr(status_buf, "[paused]")) state = "paused";

    /* parse elapsed/total times */
    char elapsed[16] = "0:00", total[16] = "0:00";
    int progress = 0;
    /* look for pattern like "1:23/4:56" */
    char *p = status_buf;
    while (*p) {
        if (*p >= '0' && *p <= '9') {
            int m1, s1, m2, s2;
            if (sscanf(p, "%d:%d/%d:%d", &m1, &s1, &m2, &s2) == 4) {
                snprintf(elapsed, sizeof(elapsed), "%d:%02d", m1, s1);
                snprintf(total, sizeof(total), "%d:%02d", m2, s2);
                int e_sec = m1 * 60 + s1;
                int t_sec = m2 * 60 + s2;
                if (t_sec > 0)
                    progress = (e_sec * 100 + t_sec / 2) / t_sec;
                break;
            }
        }
        p++;
    }

    /* JSON output with escaped strings */
    char esc_artist[1024], esc_title[1024];
    json_escape(esc_artist, sizeof(esc_artist), artist);
    json_escape(esc_title, sizeof(esc_title), title);

    printf("{\"state\":\"%s\",\"artist\":\"%s\",\"title\":\"%s\","
           "\"elapsed\":\"%s\",\"total\":\"%s\",\"progress\":%d}\n",
           state, esc_artist, esc_title, elapsed, total, progress);
    fflush(stdout);
}

static void on_mpc_line(const char *line, void *ctx)
{
    (void)line; (void)ctx;
    query_mpd();
}

int cmd_mpd(int argc, char **argv)
{
    (void)argc; (void)argv;
    signal_setup();

    query_mpd();

    popen_stream("mpc idleloop player 2>/dev/null", on_mpc_line, NULL, NULL);
    return 0;
}
