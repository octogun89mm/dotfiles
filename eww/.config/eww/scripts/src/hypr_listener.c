#include "hypr_listener.h"
#include "hypr_ipc.h"
#include <pthread.h>
#include <unistd.h>

#define POLL_IDLE_MS 2000
#define POLL_ACTIVE_MS 100
#define ACTIVE_WINDOW_MS 1000
#define RECONNECT_DELAY_US 100000

static void record_event(hypr_listener_t *listener)
{
    pthread_mutex_lock(&listener->state_mutex);
    clock_gettime(CLOCK_MONOTONIC, &listener->last_event_time);
    listener->has_event = 1;
    pthread_mutex_unlock(&listener->state_mutex);
}

static int current_poll_interval_ms(hypr_listener_t *listener)
{
    struct timespec now;
    long elapsed_ms;

    pthread_mutex_lock(&listener->state_mutex);
    if (!listener->has_event) {
        pthread_mutex_unlock(&listener->state_mutex);
        return POLL_IDLE_MS;
    }

    clock_gettime(CLOCK_MONOTONIC, &now);
    elapsed_ms = (now.tv_sec - listener->last_event_time.tv_sec) * 1000L +
                 (now.tv_nsec - listener->last_event_time.tv_nsec) / 1000000L;
    pthread_mutex_unlock(&listener->state_mutex);

    if (elapsed_ms < 0)
        return POLL_ACTIVE_MS;
    return (elapsed_ms < ACTIVE_WINDOW_MS) ? POLL_ACTIVE_MS : POLL_IDLE_MS;
}

static void *event_thread(void *arg)
{
    hypr_listener_t *listener = arg;

    for (;;) {
        int fd = hypr_event_connect();
        if (fd < 0) {
            usleep(RECONNECT_DELAY_US);
            continue;
        }
        hypr_event_reset_reader();

        char line[1024];
        int n;
        while ((n = hypr_event_readline(fd, line, sizeof(line))) > 0) {
            if (!listener->on_event || !listener->on_event(line, listener->userdata))
                continue;

            if (listener->db)
                debounce_signal(listener->db);
            if (listener->use_tick)
                record_event(listener);
        }

        close(fd);
        usleep(RECONNECT_DELAY_US);
    }
    return NULL;
}

static void *tick_thread(void *arg)
{
    hypr_listener_t *listener = arg;

    for (;;) {
        struct timespec req;
        int interval_ms = current_poll_interval_ms(listener);
        req.tv_sec = interval_ms / 1000;
        req.tv_nsec = (long)(interval_ms % 1000) * 1000000L;
        nanosleep(&req, NULL);
        debounce_signal(listener->db);
    }
    return NULL;
}

void hypr_listener_init(hypr_listener_t *listener, debounce_t *db,
                        hypr_listener_event_fn on_event, void *userdata,
                        int use_tick)
{
    listener->db = db;
    listener->on_event = on_event;
    listener->userdata = userdata;
    listener->use_tick = use_tick;
    pthread_mutex_init(&listener->state_mutex, NULL);
    listener->has_event = 0;
    listener->last_event_time.tv_sec = 0;
    listener->last_event_time.tv_nsec = 0;
}

int hypr_listener_start(hypr_listener_t *listener)
{
    pthread_t tid;

    if (pthread_create(&tid, NULL, event_thread, listener) != 0)
        return -1;
    pthread_detach(tid);

    if (listener->use_tick && listener->db) {
        if (pthread_create(&tid, NULL, tick_thread, listener) != 0)
            return -1;
        pthread_detach(tid);
    }

    return 0;
}
