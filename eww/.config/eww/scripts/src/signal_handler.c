#include "signal_handler.h"
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

#define MAX_CHILDREN 16

static pid_t children[MAX_CHILDREN];
static int num_children;

void signal_register_child(pid_t pid)
{
    if (num_children < MAX_CHILDREN)
        children[num_children++] = pid;
}

static void on_signal(int sig)
{
    for (int i = 0; i < num_children; i++)
        if (children[i] > 0) kill(children[i], SIGTERM);
    _exit(sig == SIGTERM ? 0 : 1);
}

void signal_setup(void)
{
    /* Disable stdout buffering so EWW receives updates immediately */
    setvbuf(stdout, NULL, _IONBF, 0);

    struct sigaction sa = { .sa_handler = on_signal };
    sigemptyset(&sa.sa_mask);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
}
