#include "hypr_ipc.h"
#include "hypr_listener.h"
#include "debounce.h"
#include "json_output.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static debounce_t db;
static int monitor_id;
static char last_title[4096];
static hypr_listener_t listener;

static void get_title(void)
{
    const char *title_out = "";
    cJSON *json = NULL;
    char *resp = hypr_request("j/activewindow");
    if (!resp) return;

    /* hyprctl returns literal "null" when no window is focused */
    if (strcmp(resp, "null") == 0 || resp[0] == '\0') {
        free(resp);
        title_out = "";
        goto emit;
    }

    json = cJSON_Parse(resp);
    free(resp);
    if (!json) return;

    cJSON *mon = cJSON_GetObjectItem(json, "monitor");
    if (!cJSON_IsNumber(mon) || mon->valueint != monitor_id) {
        title_out = "";
        goto emit;
    }

    cJSON *title = cJSON_GetObjectItem(json, "title");
    if (cJSON_IsString(title) && title->valuestring[0]) {
        title_out = title->valuestring;
    }

emit:
    if (strcmp(last_title, title_out) != 0) {
        snprintf(last_title, sizeof(last_title), "%s", title_out);
        puts(last_title);
        fflush(stdout);
    }
    if (json)
        cJSON_Delete(json);
}

static int should_refresh_on_event(const char *line, void *userdata)
{
    (void)userdata;
    return strncmp(line, "activewindow>>", 14) == 0 ||
           strncmp(line, "activewindowv2>>", 16) == 0 ||
           strncmp(line, "windowtitle>>", 13) == 0 ||
           strncmp(line, "windowtitlev2>>", 15) == 0 ||
           strncmp(line, "closewindow>>", 13) == 0 ||
           strncmp(line, "movewindow>>", 12) == 0 ||
           strncmp(line, "openwindow>>", 12) == 0 ||
           strncmp(line, "focusedmon>>", 12) == 0 ||
           strncmp(line, "focusedmonv2>>", 14) == 0 ||
           strncmp(line, "workspace>>", 11) == 0 ||
           strncmp(line, "workspacev2>>", 13) == 0;
}

int cmd_window_title(int argc, char **argv)
{
    monitor_id = (argc > 0) ? atoi(argv[0]) : 0;
    signal_setup();
    last_title[0] = '\0';

    if (debounce_init(&db) < 0) return 1;

    get_title();

    hypr_listener_init(&listener, &db, should_refresh_on_event, NULL, 1);
    if (hypr_listener_start(&listener) < 0) {
        debounce_destroy(&db);
        return 1;
    }

    while (debounce_wait(&db) == 0)
        get_title();

    debounce_destroy(&db);
    return 0;
}
