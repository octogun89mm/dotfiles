#ifndef JSON_OUTPUT_H
#define JSON_OUTPUT_H

#include <stddef.h>

/* Escape a string for JSON output. Handles \, ", control chars.
   Returns number of bytes written (excluding null), or -1 if truncated. */
int json_escape(char *dst, size_t dstlen, const char *src);

#endif
