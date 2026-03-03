#include "hypr_ipc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>

static char event_rbuf[8192];
static int event_rpos = 0;
static int event_rlen = 0;
static int event_last_fd = -1;

static int hypr_connect(const char *suffix)
{
    const char *xdg = getenv("XDG_RUNTIME_DIR");
    const char *his = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!xdg || !his) return -1;

    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    int n = snprintf(addr.sun_path, sizeof(addr.sun_path),
                     "%s/hypr/%s/%s", xdg, his, suffix);
    if (n < 0 || (size_t)n >= sizeof(addr.sun_path)) return -1;

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

int hypr_event_connect(void)
{
    return hypr_connect(".socket2.sock");
}

void hypr_event_reset_reader(void)
{
    event_rpos = 0;
    event_rlen = 0;
    event_last_fd = -1;
}

int hypr_event_readline(int fd, char *buf, size_t buflen)
{
    if (fd != event_last_fd) {
        event_rpos = 0;
        event_rlen = 0;
        event_last_fd = fd;
    }

    for (;;) {
        /* scan for newline in buffered data */
        for (int i = event_rpos; i < event_rlen; i++) {
            if (event_rbuf[i] == '\n') {
                int lineLen = i - event_rpos;
                if ((size_t)lineLen >= buflen) lineLen = (int)buflen - 1;
                memcpy(buf, event_rbuf + event_rpos, lineLen);
                buf[lineLen] = '\0';
                event_rpos = i + 1;
                return lineLen;
            }
        }
        /* compact buffer */
        if (event_rpos > 0) {
            memmove(event_rbuf, event_rbuf + event_rpos, event_rlen - event_rpos);
            event_rlen -= event_rpos;
            event_rpos = 0;
        }
        if (event_rlen >= (int)sizeof(event_rbuf)) {
            /* line too long, discard */
            event_rlen = 0;
        }
        int n = read(fd, event_rbuf + event_rlen, sizeof(event_rbuf) - event_rlen);
        if (n <= 0) {
            if (n == 0 && event_rlen > event_rpos) {
                int line_len = event_rlen - event_rpos;
                if ((size_t)line_len >= buflen)
                    line_len = (int)buflen - 1;
                memcpy(buf, event_rbuf + event_rpos, line_len);
                buf[line_len] = '\0';
                event_rpos = 0;
                event_rlen = 0;
                return line_len;
            }
            return n;
        }
        event_rlen += n;
    }
}

char *hypr_request(const char *cmd)
{
    int fd = hypr_connect(".socket.sock");
    if (fd < 0) return NULL;

    size_t cmdlen = strlen(cmd);
    size_t off = 0;
    while (off < cmdlen) {
        ssize_t wn = write(fd, cmd + off, cmdlen - off);
        if (wn < 0) {
            if (errno == EINTR) continue;
            close(fd);
            return NULL;
        }
        off += (size_t)wn;
    }

    size_t cap = 8192, len = 0;
    char *buf = malloc(cap);
    if (!buf) { close(fd); return NULL; }

    for (;;) {
        if (len + 4096 > cap) {
            cap *= 2;
            char *tmp = realloc(buf, cap);
            if (!tmp) { free(buf); close(fd); return NULL; }
            buf = tmp;
        }
        ssize_t n = read(fd, buf + len, cap - len - 1);
        if (n < 0) { free(buf); close(fd); return NULL; }
        if (n == 0) break;
        len += n;
    }
    buf[len] = '\0';
    close(fd);
    return buf;
}
