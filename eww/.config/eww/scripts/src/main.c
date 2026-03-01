#include <stdio.h>
#include <string.h>

/* subcommand entry points */
int cmd_workspaces(int argc, char **argv);
int cmd_window_title(int argc, char **argv);
int cmd_layout(int argc, char **argv);
int cmd_wincount(int argc, char **argv);
int cmd_submap(int argc, char **argv);
int cmd_language(int argc, char **argv);
int cmd_volume(int argc, char **argv);
int cmd_mpd(int argc, char **argv);
int cmd_cpu_usage(int argc, char **argv);
int cmd_cpu_freq(int argc, char **argv);
int cmd_cpu_temp(int argc, char **argv);
int cmd_memory_used(int argc, char **argv);
int cmd_memory_total(int argc, char **argv);
int cmd_download_speed(int argc, char **argv);
int cmd_upload_speed(int argc, char **argv);
int cmd_wifi(int argc, char **argv);
int cmd_gpu(int argc, char **argv);
int cmd_disk(int argc, char **argv);
int cmd_updates(int argc, char **argv);
int cmd_weather(int argc, char **argv);
int cmd_vpn(int argc, char **argv);

typedef int (*cmd_fn)(int argc, char **argv);

static const struct {
    const char *name;
    cmd_fn fn;
} commands[] = {
    { "workspaces",     cmd_workspaces },
    { "window-title",   cmd_window_title },
    { "layout",         cmd_layout },
    { "wincount",       cmd_wincount },
    { "submap",         cmd_submap },
    { "language",       cmd_language },
    { "volume",         cmd_volume },
    { "mpd",            cmd_mpd },
    { "cpu-usage",      cmd_cpu_usage },
    { "cpu-freq",       cmd_cpu_freq },
    { "cpu-temp",       cmd_cpu_temp },
    { "memory-used",    cmd_memory_used },
    { "memory-total",   cmd_memory_total },
    { "download-speed", cmd_download_speed },
    { "upload-speed",   cmd_upload_speed },
    { "wifi-strength",  cmd_wifi },
    { "gpu",            cmd_gpu },
    { "disk-usage",     cmd_disk },
    { "updates",        cmd_updates },
    { "weather",        cmd_weather },
    { "vpn",            cmd_vpn },
};
#define NUM_CMDS (sizeof(commands) / sizeof(commands[0]))

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: eww-bar <subcommand> [args...]\n");
        fprintf(stderr, "subcommands:");
        for (size_t i = 0; i < NUM_CMDS; i++)
            fprintf(stderr, " %s", commands[i].name);
        fprintf(stderr, "\n");
        return 1;
    }

    const char *sub = argv[1];
    for (size_t i = 0; i < NUM_CMDS; i++) {
        if (strcmp(sub, commands[i].name) == 0)
            return commands[i].fn(argc - 2, argv + 2);
    }

    fprintf(stderr, "eww-bar: unknown subcommand '%s'\n", sub);
    return 1;
}
