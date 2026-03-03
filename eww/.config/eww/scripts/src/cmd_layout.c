#include "hypr_ipc.h"
#include "debounce.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <pthread.h>
#include <time.h>

static debounce_t db;
static int monitor_id;
static char last_layout[64];
static pthread_mutex_t poll_mutex = PTHREAD_MUTEX_INITIALIZER;
static struct timespec last_event_time;
static int has_event;

#define POLL_IDLE_MS 2000
#define POLL_ACTIVE_MS 100
#define ACTIVE_WINDOW_MS 1000

static void record_event(void)
{
    pthread_mutex_lock(&poll_mutex);
    clock_gettime(CLOCK_MONOTONIC, &last_event_time);
    has_event = 1;
    pthread_mutex_unlock(&poll_mutex);
}

static int current_poll_interval_ms(void)
{
    struct timespec now;
    long elapsed_ms;

    pthread_mutex_lock(&poll_mutex);
    if (!has_event) {
        pthread_mutex_unlock(&poll_mutex);
        return POLL_IDLE_MS;
    }

    clock_gettime(CLOCK_MONOTONIC, &now);
    elapsed_ms = (now.tv_sec - last_event_time.tv_sec) * 1000L +
                 (now.tv_nsec - last_event_time.tv_nsec) / 1000000L;
    pthread_mutex_unlock(&poll_mutex);

    if (elapsed_ms < 0)
        return POLL_ACTIVE_MS;
    return (elapsed_ms < ACTIVE_WINDOW_MS) ? POLL_ACTIVE_MS : POLL_IDLE_MS;
}

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

static int should_refresh_on_event(const char *line)
{
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
                record_event();
            }
        }
        close(fd);
        usleep(HYPR_EVENT_RECONNECT_DELAY_US);
    }
    return NULL;
}

static void *tick_thread(void *arg)
{
    (void)arg;
    for (;;) {
        struct timespec req;
        int interval_ms = current_poll_interval_ms();
        req.tv_sec = interval_ms / 1000;
        req.tv_nsec = (long)(interval_ms % 1000) * 1000000L;
        nanosleep(&req, NULL);
        debounce_signal(&db);
    }
    return NULL;
}

int cmd_layout(int argc, char **argv)
{
    monitor_id = (argc > 0) ? atoi(argv[0]) : 0;
    signal_setup();
    last_layout[0] = '\0';
    has_event = 0;

    if (debounce_init(&db) < 0) return 1;

    get_layout();

    pthread_t tid;
    pthread_create(&tid, NULL, event_thread, NULL);
    pthread_detach(tid);

    pthread_t tick_tid;
    pthread_create(&tick_tid, NULL, tick_thread, NULL);
    pthread_detach(tick_tid);

    while (debounce_wait(&db) == 0)
        get_layout();

    debounce_destroy(&db);
    return 0;
}
