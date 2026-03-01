#include "popen_util.h"
#include "json_output.h"
#include "../vendor/cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#define LAT "45.48"
#define LON "-75.64"
#define API_URL "https://api.open-meteo.com/v1/forecast?latitude=" LAT "&longitude=" LON \
    "&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,apparent_temperature&timezone=America/Toronto"

#define ERROR_JSON "{\"text\":\"N/A\",\"icon\":\"\",\"class\":\"error\"}"

struct wmo_entry {
    int code;
    const char *desc;
    const char *day_icon;
    const char *night_icon;
};

static const struct wmo_entry wmo_table[] = {
    {  0, "Clear sky",          "\xef\x80\x8d", "\xef\x80\xae" },
    {  1, "Mainly clear",       "\xef\x80\x8c", "\xef\x82\x83" },
    {  2, "Partly cloudy",      "\xef\x80\x82", "\xef\x82\x86" },
    {  3, "Overcast",           "\xef\x80\x93", "\xef\x80\x93" },
    { 45, "Fog",                "\xef\x80\x83", "\xef\x81\x8a" },
    { 48, "Fog",                "\xef\x80\x83", "\xef\x81\x8a" },
    { 51, "Light drizzle",      "\xef\x80\x9a", "\xef\x80\x9a" },
    { 53, "Moderate drizzle",   "\xef\x80\x9a", "\xef\x80\x9a" },
    { 55, "Dense drizzle",      "\xef\x80\x9a", "\xef\x80\x9a" },
    { 56, "Freezing drizzle",   "\xef\x82\xb5", "\xef\x82\xb5" },
    { 57, "Freezing drizzle",   "\xef\x82\xb5", "\xef\x82\xb5" },
    { 61, "Slight rain",        "\xef\x80\x88", "\xef\x80\xa8" },
    { 63, "Moderate rain",      "\xef\x80\x99", "\xef\x80\x99" },
    { 65, "Heavy rain",         "\xef\x80\x9a", "\xef\x80\x9a" },
    { 66, "Freezing rain",      "\xef\x82\xb5", "\xef\x82\xb5" },
    { 67, "Freezing rain",      "\xef\x82\xb5", "\xef\x82\xb5" },
    { 71, "Slight snow",        "\xef\x80\x8a", "\xef\x80\xaa" },
    { 73, "Moderate snow",      "\xef\x80\x9b", "\xef\x80\x9b" },
    { 75, "Heavy snow",         "\xef\x80\x9b", "\xef\x80\x9b" },
    { 77, "Snow grains",        "\xef\x80\x9b", "\xef\x80\x9b" },
    { 80, "Slight showers",     "\xef\x80\x89", "\xef\x80\xa9" },
    { 81, "Moderate showers",   "\xef\x80\x89", "\xef\x80\x89" },
    { 82, "Violent showers",    "\xef\x80\x89", "\xef\x80\x89" },
    { 85, "Snow showers",       "\xef\x80\x9b", "\xef\x80\x9b" },
    { 86, "Snow showers",       "\xef\x80\x9b", "\xef\x80\x9b" },
    { 95, "Thunderstorm",       "\xef\x80\x9e", "\xef\x80\x9e" },
    { 96, "Thunderstorm with hail", "\xef\x80\x9d", "\xef\x80\x9d" },
    { 99, "Thunderstorm with hail", "\xef\x80\x9d", "\xef\x80\x9d" },
};
#define WMO_COUNT (sizeof(wmo_table) / sizeof(wmo_table[0]))

int cmd_weather(int argc, char **argv)
{
    (void)argc; (void)argv;

    char buf[8192];
    if (popen_read("curl -sf --connect-timeout 10 '" API_URL "' 2>/dev/null", buf, sizeof(buf)) <= 0) {
        puts(ERROR_JSON);
        return 0;
    }

    cJSON *data = cJSON_Parse(buf);
    if (!data) { puts(ERROR_JSON); return 0; }

    cJSON *current = cJSON_GetObjectItem(data, "current");
    if (!current) { cJSON_Delete(data); puts(ERROR_JSON); return 0; }

    double temp = 0, feels = 0, wind = 0;
    int humidity = 0, wmo = -1;

    cJSON *v;
    v = cJSON_GetObjectItem(current, "temperature_2m");
    if (cJSON_IsNumber(v)) temp = v->valuedouble;
    v = cJSON_GetObjectItem(current, "apparent_temperature");
    if (cJSON_IsNumber(v)) feels = v->valuedouble;
    v = cJSON_GetObjectItem(current, "wind_speed_10m");
    if (cJSON_IsNumber(v)) wind = v->valuedouble;
    v = cJSON_GetObjectItem(current, "relative_humidity_2m");
    if (cJSON_IsNumber(v)) humidity = v->valueint;
    v = cJSON_GetObjectItem(current, "weather_code");
    if (cJSON_IsNumber(v)) wmo = v->valueint;

    cJSON_Delete(data);

    /* determine day/night */
    time_t now = time(NULL);
    struct tm *tm = localtime(&now);
    int is_day = (tm->tm_hour >= 6 && tm->tm_hour < 20);

    /* lookup WMO code */
    const char *desc = "Unknown";
    const char *icon = "\xef\x81\xbb"; /* na */
    for (size_t i = 0; i < WMO_COUNT; i++) {
        if (wmo_table[i].code == wmo) {
            desc = wmo_table[i].desc;
            icon = is_day ? wmo_table[i].day_icon : wmo_table[i].night_icon;
            break;
        }
    }

    int temp_round = (int)round(temp);

    /* temperature class */
    const char *class;
    if (temp_round <= -10) class = "freezing";
    else if (temp_round <= 0) class = "cold";
    else if (temp_round <= 15) class = "cool";
    else if (temp_round <= 25) class = "warm";
    else class = "hot";

    char esc_desc[128], esc_icon[32];
    json_escape(esc_desc, sizeof(esc_desc), desc);
    json_escape(esc_icon, sizeof(esc_icon), icon);

    printf("{\"text\":\"%d\\u00b0C\",\"icon\":\"%s\",\"class\":\"%s\","
           "\"desc\":\"%s\",\"feels\":\"%.1f\",\"humidity\":\"%d\",\"wind\":\"%.1f\"}\n",
           temp_round, esc_icon, class, esc_desc, feels, humidity, wind);
    return 0;
}
