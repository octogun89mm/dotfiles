#include "hypr_ipc.h"
#include "hypr_listener.h"
#include "debounce.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

static debounce_t db;
static int monitor_id;
static char last_layout[64];
static hypr_listener_t listener;

static void get_layout(void)
{
    char *mon_resp = hypr_request("j/monitors");
    if (!mon_resp) return;
    cJSON *monitors = cJSON_Parse(mon_resp);
    free(mon_resp);
    if (!monitors) return;

    int ws_id = -1;
    cJSON *mon;
    cJSON_ArrayForEach(mon, monitors) {
        cJSON *mid = cJSON_GetObjectItem(mon, "id");
        if (cJSON_IsNumber(mid) && mid->valueint == monitor_id) {
            cJSON *aw = cJSON_GetObjectItem(mon, "activeWorkspace");
            if (aw) {
                cJSON *wid = cJSON_GetObjectItem(aw, "id");
                if (cJSON_IsNumber(wid)) ws_id = wid->valueint;
            }
            break;
        }
    }
    cJSON_Delete(monitors);
    if (ws_id < 0) return;

    char *ws_resp = hypr_request("j/workspaces");
    if (!ws_resp) return;
    cJSON *workspaces = cJSON_Parse(ws_resp);
    free(ws_resp);
    if (!workspaces) return;

    cJSON *ws;
    cJSON_ArrayForEach(ws, workspaces) {
        cJSON *wid = cJSON_GetObjectItem(ws, "id");
        if (cJSON_IsNumber(wid) && wid->valueint == ws_id) {
            cJSON *layout = cJSON_GetObjectItem(ws, "tiledLayout");
            if (cJSON_IsString(layout)) {
                char upper[64];
                size_t i;
                for (i = 0; i < sizeof(upper) - 1 && layout->valuestring[i]; i++)
                    upper[i] = toupper((unsigned char)layout->valuestring[i]);
                upper[i] = '\0';
                if (strcmp(last_layout, upper) != 0) {
                    snprintf(last_layout, sizeof(last_layout), "%s", upper);
                    puts(upper);
                    fflush(stdout);
                }
            }
            break;
        }
    }
    cJSON_Delete(workspaces);
}

static int should_refresh_on_event(const char *line, void *userdata)
{
    (void)userdata;
    return strncmp(line, "workspace>>", 11) == 0 ||
           strncmp(line, "workspacev2>>", 13) == 0 ||
           strncmp(line, "focusedmon>>", 12) == 0 ||
           strncmp(line, "focusedmonv2>>", 14) == 0 ||
           strncmp(line, "configreloaded", 14) == 0 ||
           strncmp(line, "openwindow>>", 12) == 0 ||
           strncmp(line, "closewindow>>", 13) == 0 ||
           strncmp(line, "movewindow>>", 12) == 0 ||
           strncmp(line, "windowtitle>>", 13) == 0;
}

int cmd_layout(int argc, char **argv)
{
    monitor_id = (argc > 0) ? atoi(argv[0]) : 0;
    signal_setup();
    last_layout[0] = '\0';

    if (debounce_init(&db) < 0) return 1;

    get_layout();

    hypr_listener_init(&listener, &db, should_refresh_on_event, NULL, 1);
    if (hypr_listener_start(&listener) < 0) {
        debounce_destroy(&db);
        return 1;
    }

    while (debounce_wait(&db) == 0)
        get_layout();

    debounce_destroy(&db);
    return 0;
}
