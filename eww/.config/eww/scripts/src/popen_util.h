#ifndef POPEN_UTIL_H
#define POPEN_UTIL_H

#include <stddef.h>
#include <sys/types.h>

/* Run command, read stdout into buf. Returns bytes read, -1 on error. */
int popen_read(const char *cmd, char *buf, size_t buflen);

/* Like popen_read but fails if command exceeds timeout_ms. */
int popen_read_timeout(const char *cmd, char *buf, size_t buflen, int timeout_ms);

/* Callback for popen_stream: called for each line of output. */
typedef void (*stream_cb)(const char *line, void *ctx);

/* Run command, call cb for each line. Sets *child_pid.
   Blocks until command exits or error. Returns 0 on normal exit, -1 on error. */
int popen_stream(const char *cmd, stream_cb cb, void *ctx, pid_t *child_pid);

#endif
