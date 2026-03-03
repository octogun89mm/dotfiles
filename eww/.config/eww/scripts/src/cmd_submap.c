#include "hypr_ipc.h"
#include "hypr_listener.h"
#include "signal_handler.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static char last_submap[256];
static hypr_listener_t listener;

static int handle_submap_event(const char *line, void *userdata)
{
    (void)userdata;
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
    return 0;
}

int cmd_submap(int argc, char **argv)
{
    (void)argc; (void)argv;
    signal_setup();
    last_submap[0] = '\0';

    puts(last_submap);
    fflush(stdout);
    hypr_listener_init(&listener, NULL, handle_submap_event, NULL, 0);
    if (hypr_listener_start(&listener) < 0)
        return 1;

    for (;;)
        pause();

    return 0;
}
