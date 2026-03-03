#ifndef HYPR_LISTENER_H
#define HYPR_LISTENER_H

#include "debounce.h"
#include <pthread.h>
#include <time.h>

typedef int (*hypr_listener_event_fn)(const char *line, void *userdata);

typedef struct {
    debounce_t *db;
    hypr_listener_event_fn on_event;
    void *userdata;
    int use_tick;
    pthread_mutex_t state_mutex;
    struct timespec last_event_time;
    int has_event;
} hypr_listener_t;

/* Initialize a Hyprland event listener helper.
   If db is non-NULL, a nonzero callback return will signal it.
   If use_tick is nonzero, a fallback poll tick thread is also started. */
void hypr_listener_init(hypr_listener_t *listener, debounce_t *db,
                        hypr_listener_event_fn on_event, void *userdata,
                        int use_tick);

/* Start the listener's detached thread(s). Returns 0 on success, -1 on error. */
int hypr_listener_start(hypr_listener_t *listener);

#endif
