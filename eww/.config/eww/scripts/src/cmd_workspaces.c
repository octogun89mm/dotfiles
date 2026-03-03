#include "hypr_ipc.h"
#include "hypr_listener.h"
#include "debounce.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const struct { int id; const char *name; const char *label; } ws_defs[] = {
    {  1, "1",  "A1" }, {  2, "2",  "A2" }, {  3, "3",  "A3" },
    {  4, "4",  "A4" }, {  5, "5",  "A5" }, {  6, "6",  "A6" },
    {  7, "7",  "B7" }, {  8, "8",  "B8" }, {  9, "9",  "B9" },
    { 10, "10", "B0" },
    { -99, "special:dropdown", "xD" },
    { -98, "special:magic",    "xM" },
};
#define NUM_WS (sizeof(ws_defs) / sizeof(ws_defs[0]))
static char last_json[4096];
static debounce_t db;
static hypr_listener_t listener;

static void query_workspaces(void)
{
    char *ws_resp = hypr_request("j/workspaces");
    char *aw_resp = hypr_request("j/activeworkspace");
    char *mon_resp = hypr_request("j/monitors");
    if (!ws_resp || !aw_resp || !mon_resp) {
        free(ws_resp); free(aw_resp); free(mon_resp);
        return;
    }

    cJSON *workspaces = cJSON_Parse(ws_resp);
    cJSON *active_ws = cJSON_Parse(aw_resp);
    cJSON *monitors = cJSON_Parse(mon_resp);
    free(ws_resp); free(aw_resp); free(mon_resp);
    if (!workspaces || !active_ws || !monitors) {
        cJSON_Delete(workspaces); cJSON_Delete(active_ws); cJSON_Delete(monitors);
        return;
    }

    int active_id = 0;
    cJSON *aid = cJSON_GetObjectItem(active_ws, "id");
    if (cJSON_IsNumber(aid)) active_id = aid->valueint;

    /* collect visible workspace IDs */
    int visible_ids[16] = {0};
    int num_visible = 0;
    cJSON *mon;
    cJSON_ArrayForEach(mon, monitors) {
        cJSON *aw = cJSON_GetObjectItem(mon, "activeWorkspace");
        if (aw) {
            cJSON *mid = cJSON_GetObjectItem(aw, "id");
            if (cJSON_IsNumber(mid) && num_visible < 16)
                visible_ids[num_visible++] = mid->valueint;
        }
        /* special workspace visibility */
        cJSON *sw = cJSON_GetObjectItem(mon, "specialWorkspace");
        if (sw) {
            cJSON *sid = cJSON_GetObjectItem(sw, "id");
            if (cJSON_IsNumber(sid) && sid->valueint != 0 && num_visible < 16)
                visible_ids[num_visible++] = sid->valueint;
        }
    }

    /* collect occupied workspace IDs (windows > 0) */
    int occupied_ids[64] = {0};
    int num_occupied = 0;
    cJSON *w;
    cJSON_ArrayForEach(w, workspaces) {
        cJSON *wid = cJSON_GetObjectItem(w, "id");
        cJSON *wwin = cJSON_GetObjectItem(w, "windows");
        if (cJSON_IsNumber(wid) && cJSON_IsNumber(wwin) && wwin->valueint > 0) {
            if (num_occupied < 64) occupied_ids[num_occupied++] = wid->valueint;
        }
    }

    /* build output JSON */
    char buf[4096];
    int pos = 0;
    pos += snprintf(buf + pos, sizeof(buf) - pos, "[");

    for (size_t i = 0; i < NUM_WS; i++) {
        int id = ws_defs[i].id;
        int is_active = (id == active_id);
        int is_occupied = 0, is_visible = 0;
        for (int j = 0; j < num_occupied; j++)
            if (occupied_ids[j] == id) { is_occupied = 1; break; }
        for (int j = 0; j < num_visible; j++)
            if (visible_ids[j] == id) { is_visible = 1; break; }

        if (i > 0) pos += snprintf(buf + pos, sizeof(buf) - pos, ",");
        pos += snprintf(buf + pos, sizeof(buf) - pos,
            "{\"id\":%d,\"name\":\"%s\",\"label\":\"%s\","
            "\"active\":%s,\"occupied\":%s,\"visible\":%s}",
            id, ws_defs[i].name, ws_defs[i].label,
            is_active ? "true" : "false",
            is_occupied ? "true" : "false",
            is_visible ? "true" : "false");
    }
    pos += snprintf(buf + pos, sizeof(buf) - pos, "]");
    if (strcmp(last_json, buf) != 0) {
        snprintf(last_json, sizeof(last_json), "%s", buf);
        puts(last_json);
        fflush(stdout);
    }

    cJSON_Delete(workspaces);
    cJSON_Delete(active_ws);
    cJSON_Delete(monitors);
}

static int should_refresh_on_event(const char *line, void *userdata)
{
    (void)userdata;
    return strncmp(line, "workspace>>", 11) == 0 ||
           strncmp(line, "workspacev2>>", 13) == 0 ||
           strncmp(line, "activespecial>>", 15) == 0 ||
           strncmp(line, "activespecialv2>>", 17) == 0 ||
           strncmp(line, "focusedmon>>", 12) == 0 ||
           strncmp(line, "focusedmonv2>>", 14) == 0 ||
           strncmp(line, "createworkspace>>", 17) == 0 ||
           strncmp(line, "createworkspacev2>>", 19) == 0 ||
           strncmp(line, "destroyworkspace>>", 18) == 0 ||
           strncmp(line, "destroyworkspacev2>>", 20) == 0 ||
           strncmp(line, "openwindow>>", 12) == 0 ||
           strncmp(line, "closewindow>>", 13) == 0 ||
           strncmp(line, "movewindow>>", 12) == 0 ||
           strncmp(line, "movewindowv2>>", 14) == 0;
}

int cmd_workspaces(int argc, char **argv)
{
    (void)argc; (void)argv;
    signal_setup();
    last_json[0] = '\0';

    if (debounce_init(&db) < 0) return 1;

    query_workspaces();

    hypr_listener_init(&listener, &db, should_refresh_on_event, NULL, 1);
    if (hypr_listener_start(&listener) < 0) {
        debounce_destroy(&db);
        return 1;
    }

    while (debounce_wait(&db) == 0)
        query_workspaces();

    debounce_destroy(&db);
    return 0;
}
