#ifndef DEBOUNCE_H
#define DEBOUNCE_H

typedef struct {
    int read_fd;
    int write_fd;
} debounce_t;

/* Create a debounce pipe. Returns 0 on success, -1 on error. */
int debounce_init(debounce_t *d);

/* Signal the debounce pipe (called from event thread). */
void debounce_signal(debounce_t *d);

/* Wait for signal, then drain + debounce (50ms). Blocks until signaled.
   Returns 0 on success, -1 on error/EOF. */
int debounce_wait(debounce_t *d);

/* Close the debounce pipe. */
void debounce_destroy(debounce_t *d);

#endif
