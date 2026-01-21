#!/usr/bin/env python3

import json
import urllib.request
import urllib.error
import sys

# Weather station for wttr.in (e.g., "~ynd" for Gatineau)
LOCATION = "~ynd"

WTTR_URL = f"https://wttr.in/{LOCATION}?format=j1"


def fetch_weather():
    try:
        req = urllib.request.Request(
            WTTR_URL,
            headers={"User-Agent": "curl/7.68.0"}
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.loads(response.read().decode())
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
        return None


def main():
    data = fetch_weather()

    if data is None:
        output = {
            "text": "N/A",
            "alt": "0",
            "tooltip": "Failed to fetch weather data",
            "class": "error",
            "percentage": 0
        }
        print(json.dumps(output))
        return

    try:
        current = data["current_condition"][0]
        area = data["nearest_area"][0]

        temp_c = current["temp_C"]
        feels_like = current["FeelsLikeC"]
        humidity = current["humidity"]
        weather_code = current["weatherCode"]
        weather_desc = current["weatherDesc"][0]["value"]
        wind_speed = current["windspeedKmph"]
        wind_dir = current["winddir16Point"]

        location_name = area["areaName"][0]["value"]
        region = area["region"][0]["value"]

        text = f"{temp_c}°C"

        tooltip_lines = [
            f"<b>{location_name}, {region}</b>",
            f"<b>{weather_desc}</b>",
            f"",
            f"Temperature: {temp_c}°C",
            f"Feels like: {feels_like}°C",
            f"Humidity: {humidity}%",
            f"Wind: {wind_speed} km/h {wind_dir}",
        ]
        tooltip = "\r".join(tooltip_lines)

        # Determine class based on temperature
        temp_int = int(temp_c)
        if temp_int <= -10:
            css_class = "freezing"
        elif temp_int <= 0:
            css_class = "cold"
        elif temp_int <= 15:
            css_class = "cool"
        elif temp_int <= 25:
            css_class = "warm"
        else:
            css_class = "hot"

        # Percentage based on temperature (-40 to 40 range mapped to 0-100)
        percentage = max(0, min(100, int((temp_int + 40) * 100 / 80)))

        output = {
            "text": text,
            "alt": weather_code,
            "tooltip": tooltip,
            "class": css_class,
            "percentage": percentage
        }

        print(json.dumps(output))

    except (KeyError, IndexError) as e:
        output = {
            "text": "Error",
            "alt": "0",
            "tooltip": f"Failed to parse weather data: {e}",
            "class": "error",
            "percentage": 0
        }
        print(json.dumps(output))


if __name__ == "__main__":
    main()
