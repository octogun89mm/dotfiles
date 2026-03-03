#ifndef SIGNAL_HANDLER_H
#define SIGNAL_HANDLER_H

#include <sys/types.h>

/* Register a child PID to kill on cleanup. */
void signal_register_child(pid_t pid);

/* Install signal handlers. Call once from main(). */
void signal_setup(void);

#endif
