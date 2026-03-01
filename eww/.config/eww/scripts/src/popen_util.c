#include "popen_util.h"
#include "signal_handler.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>
#include <poll.h>
#include <fcntl.h>
#include <time.h>

static long long now_monotonic_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000LL + (long long)ts.tv_nsec / 1000000LL;
}

static int read_with_timeout(const char *cmd, char *buf, size_t buflen, int timeout_ms)
{
    if (!buf || buflen == 0) return -1;

    int pipefd[2];
    if (pipe(pipefd) < 0) {
        buf[0] = '\0';
        return -1;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        buf[0] = '\0';
        return -1;
    }

    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);
        execl("/bin/sh", "sh", "-c", cmd, NULL);
        _exit(127);
    }

    close(pipefd[1]);
    int flags = fcntl(pipefd[0], F_GETFL, 0);
    if (flags >= 0)
        fcntl(pipefd[0], F_SETFL, flags | O_NONBLOCK);

    size_t total = 0;
    int timed_out = 0;
    long long deadline = (timeout_ms > 0) ? now_monotonic_ms() + timeout_ms : 0;

    for (;;) {
        int poll_timeout = -1;
        if (timeout_ms > 0) {
            long long remaining = deadline - now_monotonic_ms();
            if (remaining <= 0) {
                timed_out = 1;
                break;
            }
            poll_timeout = (remaining > 2000) ? 2000 : (int)remaining;
        }

        struct pollfd pfd = { .fd = pipefd[0], .events = POLLIN | POLLHUP | POLLERR };
        int pr = poll(&pfd, 1, poll_timeout);
        if (pr < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (pr == 0) {
            timed_out = 1;
            break;
        }

        if (!(pfd.revents & (POLLIN | POLLHUP | POLLERR)))
            continue;

        ssize_t n = read(pipefd[0], buf + total, buflen - total - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) continue;
            break;
        }
        if (n == 0) break;
        total += (size_t)n;
        if (total + 1 >= buflen) break;
    }

    buf[total] = '\0';

    /* strip trailing newline */
    while (total > 0 && (buf[total-1] == '\n' || buf[total-1] == '\r'))
        buf[--total] = '\0';

    close(pipefd[0]);

    if (timed_out) {
        kill(pid, SIGTERM);
        usleep(100000);
        if (waitpid(pid, NULL, WNOHANG) == 0) {
            kill(pid, SIGKILL);
            waitpid(pid, NULL, 0);
        }
        buf[0] = '\0';
        return -1;
    }

    waitpid(pid, NULL, 0);
    return (int)total;
}

int popen_read(const char *cmd, char *buf, size_t buflen)
{
    return read_with_timeout(cmd, buf, buflen, -1);
}

int popen_read_timeout(const char *cmd, char *buf, size_t buflen, int timeout_ms)
{
    return read_with_timeout(cmd, buf, buflen, timeout_ms);
}

int popen_stream(const char *cmd, stream_cb cb, void *ctx, pid_t *child_pid)
{
    int pipefd[2];
    if (pipe(pipefd) < 0) return -1;

    pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        return -1;
    }
    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);
        execl("/bin/sh", "sh", "-c", cmd, NULL);
        _exit(127);
    }
    close(pipefd[1]);
    if (child_pid) *child_pid = pid;
    signal_register_child(pid);

    FILE *fp = fdopen(pipefd[0], "r");
    if (!fp) {
        close(pipefd[0]);
        kill(pid, SIGTERM);
        waitpid(pid, NULL, 0);
        return -1;
    }

    char line[4096];
    while (fgets(line, sizeof(line), fp)) {
        /* strip newline */
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
            line[--len] = '\0';
        cb(line, ctx);
    }
    fclose(fp);
    waitpid(pid, NULL, 0);
    return 0;
}
