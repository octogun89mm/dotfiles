#include "proc_util.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int read_ull(const char *path, unsigned long long *val)
{
    FILE *fp = fopen(path, "r");
    if (!fp) return -1;
    int ret = (fscanf(fp, "%llu", val) == 1) ? 0 : -1;
    fclose(fp);
    return ret;
}

int read_line(const char *path, char *buf, size_t buflen)
{
    if (!buf || buflen == 0) return -1;

    FILE *fp = fopen(path, "r");
    if (!fp) return -1;
    if (!fgets(buf, buflen, fp)) {
        fclose(fp);
        return -1;
    }
    fclose(fp);
    size_t len = strlen(buf);
    while (len > 0 && (buf[len-1] == '\n' || buf[len-1] == '\r'))
        buf[--len] = '\0';
    return (int)len;
}
