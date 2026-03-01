#ifndef PROC_UTIL_H
#define PROC_UTIL_H

#include <stddef.h>

/* Read an unsigned long long from a sysfs/procfs file. Returns 0 on success. */
int read_ull(const char *path, unsigned long long *val);

/* Read the first line from a file into buf. Returns bytes read, -1 on error. */
int read_line(const char *path, char *buf, size_t buflen);

#endif
