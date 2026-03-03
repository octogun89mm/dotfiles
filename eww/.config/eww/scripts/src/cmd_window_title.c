#include "hypr_ipc.h"
#include "debounce.h"
#include "json_output.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <time.h>

static debounce_t db;
static int monitor_id;
static char last_title[4096];
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

static int should_refresh_on_event(const char *line)
{
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

static void *event_thread(void *arg)
{
    (void)arg;
    for (;;) {
        int fd = hypr_event_connect();
        if (fd < 0) { sleep(1); continue; }

        char line[1024];
        int n;
        while ((n = hypr_event_readline(fd, line, sizeof(line))) > 0) {
            if (should_refresh_on_event(line)) {
                debounce_signal(&db);
                record_event();
            }
        }
        close(fd);
        sleep(1);
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

int cmd_window_title(int argc, char **argv)
{
    monitor_id = (argc > 0) ? atoi(argv[0]) : 0;
    signal_setup();
    last_title[0] = '\0';
    has_event = 0;

    if (debounce_init(&db) < 0) return 1;

    get_title();

    pthread_t tid;
    pthread_create(&tid, NULL, event_thread, NULL);
    pthread_detach(tid);

    pthread_t tick_tid;
    pthread_create(&tick_tid, NULL, tick_thread, NULL);
    pthread_detach(tick_tid);

    while (debounce_wait(&db) == 0)
        get_title();

    debounce_destroy(&db);
    return 0;
}
