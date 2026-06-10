#!/usr/bin/env bash

set -euo pipefail

df -BG / /mnt/*/ 2>/dev/null | awk '
NR > 1 && !seen[$1]++ {
    gsub(/G/, "", $2)
    gsub(/G/, "", $3)
    mount = $6
    label = mount == "/" ? "ROOT" : mount
    if (mount != "/") {
        n = split(mount, parts, "/")
        label = toupper(parts[n])
    }
    printf "%s|%s|%s|%s\n", mount, label, $3, $2
}' | jq -Rcs '
split("\n")
| map(select(length > 0))
| map(split("|"))
| map({
    mount: .[0],
    label: .[1],
    used: .[2],
    total: .[3]
  })'
