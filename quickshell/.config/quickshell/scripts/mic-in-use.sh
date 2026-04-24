#!/usr/bin/env bash

set -euo pipefail

if ! command -v pactl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    printf '{"active":false,"apps":[]}\n'
    exit 0
fi

sources=$(pactl -f json list sources 2>/dev/null || printf '[]')
outputs=$(pactl -f json list source-outputs 2>/dev/null || printf '[]')

jq -cn --argjson sources "$sources" --argjson outputs "$outputs" '
    ($sources | map({(.index | tostring): .}) | add // {}) as $byIdx
    | [ $outputs[]
        | select((.corked // false) == false)
        | . as $o
        | ($byIdx[$o.source | tostring]) as $s
        | select($s != null)
        | select((($s.properties["device.class"] // "") != "monitor")
                 and (($s.name // "") | endswith(".monitor") | not))
        | ( $o.properties["application.name"]
            // $o.properties["application.process.binary"]
            // $o.properties["node.name"]
            // "unknown" )
      ] as $apps
    | { active: (($apps | length) > 0), apps: ($apps | unique) }
'
