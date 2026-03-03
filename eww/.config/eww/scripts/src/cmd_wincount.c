#include "hypr_ipc.h"
#include "debounce.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

static debounce_t db;
static int monitor_id;
static int last_wincount = -1;

static void get_wincount(void)
{
    int count = 0;
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

    if (ws_id < 0) goto emit;

    char *ws_resp = hypr_request("j/workspaces");
    if (!ws_resp) goto emit;
    cJSON *workspaces = cJSON_Parse(ws_resp);
    free(ws_resp);
    if (!workspaces) goto emit;

    cJSON *ws;
    cJSON_ArrayForEach(ws, workspaces) {
        cJSON *wid = cJSON_GetObjectItem(ws, "id");
        if (cJSON_IsNumber(wid) && wid->valueint == ws_id) {
            cJSON *wwin = cJSON_GetObjectItem(ws, "windows");
            if (cJSON_IsNumber(wwin))
                count = wwin->valueint;
            cJSON_Delete(workspaces);
            goto emit;
        }
    }
    cJSON_Delete(workspaces);

emit:
    if (count != last_wincount) {
        last_wincount = count;
        printf("%d\n", count);
        fflush(stdout);
    }
}

static int should_refresh_on_event(const char *line)
{
    return strncmp(line, "openwindow>>", 12) == 0 ||
           strncmp(line, "closewindow>>", 13) == 0 ||
           strncmp(line, "movewindow>>", 12) == 0 ||
           strncmp(line, "workspace>>", 11) == 0 ||
           strncmp(line, "workspacev2>>", 13) == 0 ||
           strncmp(line, "focusedmon>>", 12) == 0 ||
           strncmp(line, "focusedmonv2>>", 14) == 0;
}

static void *event_thread(void *arg)
{
    (void)arg;
    for (;;) {
        int fd = hypr_event_connect();
        if (fd < 0) { usleep(HYPR_EVENT_RECONNECT_DELAY_US); continue; }

        char line[1024];
        int n;
        while ((n = hypr_event_readline(fd, line, sizeof(line))) > 0) {
            if (should_refresh_on_event(line)) {
                debounce_signal(&db);
            }
        }
        close(fd);
        usleep(HYPR_EVENT_RECONNECT_DELAY_US);
    }
    return NULL;
}

int cmd_wincount(int argc, char **argv)
{
    monitor_id = (argc > 0) ? atoi(argv[0]) : 0;
    signal_setup();
    last_wincount = -1;

    if (debounce_init(&db) < 0) return 1;

    get_wincount();

    pthread_t tid;
    pthread_create(&tid, NULL, event_thread, NULL);
    pthread_detach(tid);

    while (debounce_wait(&db) == 0)
        get_wincount();

    debounce_destroy(&db);
    return 0;
}
