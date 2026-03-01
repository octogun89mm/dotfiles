#include "json_output.h"
#include <stdio.h>

int json_escape(char *dst, size_t dstlen, const char *src)
{
    size_t di = 0;
    if (!src) {
        if (dstlen > 0) dst[0] = '\0';
        return 0;
    }
    for (; *src && di + 1 < dstlen; src++) {
        unsigned char c = (unsigned char)*src;
        if (c == '"' || c == '\\') {
            if (di + 2 >= dstlen) break;
            dst[di++] = '\\';
            dst[di++] = c;
        } else if (c == '\n') {
            if (di + 2 >= dstlen) break;
            dst[di++] = '\\';
            dst[di++] = 'n';
        } else if (c == '\r') {
            if (di + 2 >= dstlen) break;
            dst[di++] = '\\';
            dst[di++] = 'r';
        } else if (c == '\t') {
            if (di + 2 >= dstlen) break;
            dst[di++] = '\\';
            dst[di++] = 't';
        } else if (c < 0x20) {
            if (di + 6 >= dstlen) break;
            di += snprintf(dst + di, dstlen - di, "\\u%04x", c);
        } else {
            dst[di++] = c;
        }
    }
    if (di < dstlen) dst[di] = '\0';
    else if (dstlen > 0) dst[dstlen - 1] = '\0';
    return (int)di;
}
