#!/usr/bin/env bash

is_running() {
    local backend
    backend="$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null)"
    [[ "$backend" == "Running" ]]
}

toggle() {
    if is_running; then
        tailscale down &>/dev/null
    else
        tailscale up &>/dev/null
    fi
}

status() {
    local json self_ip exit_node peers
    json="$(tailscale status --json 2>/dev/null)"

    if [[ -z "$json" ]] || ! is_running; then
        jq --unbuffered --compact-output -n \
            '{
                text: "OFF",
                alt: "󰖃",
                class: "tailscale-disconnected",
                tooltip: "Tailscale is stopped"
            }'
        return
    fi

    self_ip="$(jq -r '.Self.TailscaleIPs[0] // "?"' <<< "$json")"
    exit_node="$(jq -r '[.Peer[]? | select(.ExitNode==true) | .HostName] | first // "none"' <<< "$json")"
    peers="$(jq -r '[.Peer[]? | select(.Online==true)] | length' <<< "$json")"

    jq --unbuffered --compact-output -n \
        --arg self_ip "$self_ip" \
        --arg exit_node "$exit_node" \
        --arg peers "$peers" \
        '{
            text: "ON",
            alt: "󰖂",
            class: "tailscale-connected",
            tooltip: (
                [
                    "Tailscale IP: " + $self_ip,
                    "Exit node: " + $exit_node,
                    "Peers online: " + $peers
                ] | join("\n")
            )
        }'
}

case "$1" in
    toggle) toggle ;;
    *) status ;;
esac
