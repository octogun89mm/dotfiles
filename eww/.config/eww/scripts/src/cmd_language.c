#include "hypr_ipc.h"
#include "signal_handler.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

static char last_lang[8];

static void shorten_layout(const char *layout, char *out, size_t outlen)
{
    if (strstr(layout, "English") || strstr(layout, "us")) {
        snprintf(out, outlen, "EN");
    } else if (strstr(layout, "French") || strstr(layout, "Canadian") || strstr(layout, "ca")) {
        snprintf(out, outlen, "FR");
    } else if (strstr(layout, "German") || strstr(layout, "de")) {
        snprintf(out, outlen, "DE");
    } else if (strstr(layout, "Spanish") || strstr(layout, "es")) {
        snprintf(out, outlen, "ES");
    } else {
        /* take first 2 chars, uppercase */
        size_t i;
        for (i = 0; i < 2 && layout[i]; i++)
            out[i] = toupper((unsigned char)layout[i]);
        out[i] = '\0';
    }
}

static void emit_lang(const char *lang)
{
    if (!lang) return;
    if (strcmp(last_lang, lang) == 0) return;
    snprintf(last_lang, sizeof(last_lang), "%s", lang);
    puts(last_lang);
    fflush(stdout);
}

static void print_initial(void)
{
    char *resp = hypr_request("j/devices");
    if (!resp) { emit_lang("EN"); return; }

    cJSON *json = cJSON_Parse(resp);
    free(resp);
    if (!json) { emit_lang("EN"); return; }

    const char *keymap = "English (US)";
    cJSON *keyboards = cJSON_GetObjectItem(json, "keyboards");
    if (cJSON_IsArray(keyboards)) {
        cJSON *kb;
        cJSON_ArrayForEach(kb, keyboards) {
            cJSON *main_kb = cJSON_GetObjectItem(kb, "main");
            if (cJSON_IsTrue(main_kb)) {
                cJSON *ak = cJSON_GetObjectItem(kb, "active_keymap");
                if (cJSON_IsString(ak) && ak->valuestring[0])
                    keymap = ak->valuestring;
                break;
            }
        }
    }

    char shortened[8];
    shorten_layout(keymap, shortened, sizeof(shortened));
    emit_lang(shortened);
    cJSON_Delete(json);
}

int cmd_language(int argc, char **argv)
{
    (void)argc; (void)argv;
    signal_setup();
    last_lang[0] = '\0';

    print_initial();

    for (;;) {
        int fd = hypr_event_connect();
        if (fd < 0) { sleep(1); continue; }

        char line[1024];
        int n;
        while ((n = hypr_event_readline(fd, line, sizeof(line))) > 0) {
            if (strncmp(line, "activelayout>>", 14) == 0 ||
                strncmp(line, "activelayoutv2>>", 16) == 0) {
                /* format: activelayout>>KEYBOARD,LAYOUT_NAME */
                char *payload = line + ((line[13] == '>') ? 14 : 16);
                char *comma = strchr(payload, ',');
                if (comma) {
                    char shortened[8];
                    shorten_layout(comma + 1, shortened, sizeof(shortened));
                    emit_lang(shortened);
                }
            }
        }
        close(fd);
        sleep(1);
    }
    return 0;
}
