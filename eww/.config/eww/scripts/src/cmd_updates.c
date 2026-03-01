#include "popen_util.h"
#include <stdio.h>
#include <string.h>

static int count_lines(const char *s)
{
    if (!s || !s[0]) return 0;
    int count = 0;
    for (const char *p = s; *p; p++)
        if (*p == '\n') count++;
    /* count last line if no trailing newline */
    if (s[0] && s[strlen(s) - 1] != '\n') count++;
    return count;
}

int cmd_updates(int argc, char **argv)
{
    (void)argc; (void)argv;

    char repo_buf[8192], aur_buf[8192];

    int repo_len = popen_read("checkupdates 2>/dev/null", repo_buf, sizeof(repo_buf));
    int aur_len = popen_read("yay -Qua 2>/dev/null", aur_buf, sizeof(aur_buf));

    int repo = (repo_len > 0) ? count_lines(repo_buf) : 0;
    int aur = (aur_len > 0) ? count_lines(aur_buf) : 0;

    printf("%d", repo + aur);
    return 0;
}
