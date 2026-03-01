#include "debounce.h"
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <errno.h>

int debounce_init(debounce_t *d)
{
    int fds[2];
    int flags;
    if (pipe(fds) < 0) return -1;

    /* set read/write ends non-blocking for safe drain and bounded signaling */
    flags = fcntl(fds[0], F_GETFL);
    if (flags < 0 || fcntl(fds[0], F_SETFL, flags | O_NONBLOCK) < 0) {
        close(fds[0]);
        close(fds[1]);
        return -1;
    }
    flags = fcntl(fds[1], F_GETFL);
    if (flags < 0 || fcntl(fds[1], F_SETFL, flags | O_NONBLOCK) < 0) {
        close(fds[0]);
        close(fds[1]);
        return -1;
    }

    d->read_fd = fds[0];
    d->write_fd = fds[1];
    return 0;
}

void debounce_signal(debounce_t *d)
{
    char c = 1;
    for (;;) {
        if (write(d->write_fd, &c, 1) == 1) return;
        if (errno == EINTR) continue;
        return;
    }
}

int debounce_wait(debounce_t *d)
{
    struct pollfd pfd = { .fd = d->read_fd, .events = POLLIN };
    char drain[64];

    /* block until first signal */
    int ret = poll(&pfd, 1, -1);
    if (ret <= 0) return -1;
    /* drain initial */
    while (read(d->read_fd, drain, sizeof(drain)) > 0)
        ;
    /* wait 50ms for more events to settle */
    for (;;) {
        ret = poll(&pfd, 1, 50);
        if (ret <= 0) break;
        while (read(d->read_fd, drain, sizeof(drain)) > 0)
            ;
    }
    return 0;
}

void debounce_destroy(debounce_t *d)
{
    if (d->read_fd >= 0) close(d->read_fd);
    if (d->write_fd >= 0) close(d->write_fd);
    d->read_fd = d->write_fd = -1;
}
