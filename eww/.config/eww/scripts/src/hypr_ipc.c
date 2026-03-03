#include "hypr_ipc.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>

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

int hypr_event_readline(int fd, char *buf, size_t buflen)
{
    static char rbuf[8192];
    static int rpos = 0, rlen = 0;
    static int last_fd = -1;

    if (fd != last_fd) {
        rpos = 0;
        rlen = 0;
        last_fd = fd;
    }

    for (;;) {
        /* scan for newline in buffered data */
        for (int i = rpos; i < rlen; i++) {
            if (rbuf[i] == '\n') {
                int lineLen = i - rpos;
                if ((size_t)lineLen >= buflen) lineLen = (int)buflen - 1;
                memcpy(buf, rbuf + rpos, lineLen);
                buf[lineLen] = '\0';
                rpos = i + 1;
                return lineLen;
            }
        }
        /* compact buffer */
        if (rpos > 0) {
            memmove(rbuf, rbuf + rpos, rlen - rpos);
            rlen -= rpos;
            rpos = 0;
        }
        if (rlen >= (int)sizeof(rbuf)) {
            /* line too long, discard */
            rlen = 0;
        }
        int n = read(fd, rbuf + rlen, sizeof(rbuf) - rlen);
        if (n <= 0) {
            if (n == 0 && rlen > 0) {
                int line_len = rlen - rpos;
                if ((size_t)line_len >= buflen)
                    line_len = (int)buflen - 1;
                memcpy(buf, rbuf + rpos, line_len);
                buf[line_len] = '\0';
                rpos = 0;
                rlen = 0;
                return line_len;
            }
            return n;
        }
        rlen += n;
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
