#!/usr/bin/env bash

# Weather script using Open-Meteo API with Weather Icons font glyphs
# Location: Gatineau, QC
LAT=45.48
LON=-75.64

data=$(curl -sf --connect-timeout 10 \
    "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,apparent_temperature&timezone=America/Toronto" 2>/dev/null)

if [[ -z "$data" ]]; then
    echo '{"text":"N/A","icon":"","class":"error"}'
    exit 0
fi

temp=$(echo "$data" | jq -r '.current.temperature_2m')
feels=$(echo "$data" | jq -r '.current.apparent_temperature')
humidity=$(echo "$data" | jq -r '.current.relative_humidity_2m')
wind=$(echo "$data" | jq -r '.current.wind_speed_10m')
wmo=$(echo "$data" | jq -r '.current.weather_code')
hour=$(date +%H)

# Determine if it's daytime (6-20)
is_day=true
(( hour < 6 || hour >= 20 )) && is_day=false

# Map WMO weather codes to Weather Icons unicode codepoints and descriptions
# Font: weathericons-regular-webfont.ttf
case $wmo in
    0)
        desc="Clear sky"
        $is_day && icon=$'\uf00d' || icon=$'\uf02e' ;;  # day-sunny / night-clear
    1)
        desc="Mainly clear"
        $is_day && icon=$'\uf00c' || icon=$'\uf083' ;;  # day-cloudy-gusts / night-alt-cloudy
    2)
        desc="Partly cloudy"
        $is_day && icon=$'\uf002' || icon=$'\uf086' ;;  # day-cloudy / night-alt-cloudy
    3)
        desc="Overcast"
        icon=$'\uf013' ;;  # cloud
    45|48)
        desc="Fog"
        $is_day && icon=$'\uf003' || icon=$'\uf04a' ;;  # day-fog / night-fog
    51)
        desc="Light drizzle"
        icon=$'\uf01a' ;;  # rain
    53)
        desc="Moderate drizzle"
        icon=$'\uf01a' ;;
    55)
        desc="Dense drizzle"
        icon=$'\uf01a' ;;
    56|57)
        desc="Freezing drizzle"
        icon=$'\uf0b5' ;;  # rain-mix
    61)
        desc="Slight rain"
        $is_day && icon=$'\uf008' || icon=$'\uf028' ;;  # day-rain / night-rain
    63)
        desc="Moderate rain"
        icon=$'\uf019' ;;  # rain
    65)
        desc="Heavy rain"
        icon=$'\uf01a' ;;  # rain
    66|67)
        desc="Freezing rain"
        icon=$'\uf0b5' ;;  # rain-mix
    71)
        desc="Slight snow"
        $is_day && icon=$'\uf00a' || icon=$'\uf02a' ;;  # day-snow / night-snow
    73)
        desc="Moderate snow"
        icon=$'\uf01b' ;;  # snow
    75)
        desc="Heavy snow"
        icon=$'\uf01b' ;;
    77)
        desc="Snow grains"
        icon=$'\uf01b' ;;
    80)
        desc="Slight showers"
        $is_day && icon=$'\uf009' || icon=$'\uf029' ;;  # day-showers / night-showers
    81)
        desc="Moderate showers"
        icon=$'\uf009' ;;
    82)
        desc="Violent showers"
        icon=$'\uf009' ;;
    85|86)
        desc="Snow showers"
        icon=$'\uf01b' ;;
    95)
        desc="Thunderstorm"
        icon=$'\uf01e' ;;  # thunderstorm
    96|99)
        desc="Thunderstorm with hail"
        icon=$'\uf01d' ;;  # storm-showers
    *)
        desc="Unknown"
        icon=$'\uf07b' ;;  # na
esac

# Round temperature
temp_round=$(printf "%.0f" "$temp")

# Build text: temperature only (icon is a separate field)
text="${temp_round}°C"

# Determine class based on temperature
if (( temp_round <= -10 )); then
    class="freezing"
elif (( temp_round <= 0 )); then
    class="cold"
elif (( temp_round <= 15 )); then
    class="cool"
elif (( temp_round <= 25 )); then
    class="warm"
else
    class="hot"
fi

jq -nc \
    --arg text "$text" \
    --arg icon "$icon" \
    --arg class "$class" \
    --arg desc "$desc" \
    --arg feels "$feels" \
    --arg humidity "$humidity" \
    --arg wind "$wind" \
    '{text: $text, icon: $icon, class: $class, desc: $desc, feels: $feels, humidity: $humidity, wind: $wind}'
