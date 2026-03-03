#ifndef SIGNAL_HANDLER_H
#define SIGNAL_HANDLER_H

#include <sys/types.h>

typedef void (*cleanup_fn)(void);

/* Register a cleanup function called on SIGTERM/SIGINT/SIGHUP. */
void signal_register_cleanup(cleanup_fn fn);

/* Register a child PID to kill on cleanup. */
void signal_register_child(pid_t pid);

/* Install signal handlers. Call once from main(). */
void signal_setup(void);

#endif
