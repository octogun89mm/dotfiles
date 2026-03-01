#include "hypr_ipc.h"
#include "signal_handler.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static char last_submap[256];

int cmd_submap(int argc, char **argv)
{
    (void)argc; (void)argv;
    signal_setup();
    last_submap[0] = '\0';

    puts(last_submap);
    fflush(stdout);

    for (;;) {
        int fd = hypr_event_connect();
        if (fd < 0) { sleep(1); continue; }

        char line[1024];
        int n;
        while ((n = hypr_event_readline(fd, line, sizeof(line))) > 0) {
            if (strncmp(line, "submap>>", 8) == 0) {
                const char *new_submap = line + 8;
                if (strcmp(last_submap, new_submap) != 0) {
                    size_t len = strlen(new_submap);
                    if (len >= sizeof(last_submap))
                        len = sizeof(last_submap) - 1;
                    memcpy(last_submap, new_submap, len);
                    last_submap[len] = '\0';
                    puts(last_submap);
                    fflush(stdout);
                }
            }
        }
        close(fd);
        sleep(1);
    }
    return 0;
}
