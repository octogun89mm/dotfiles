# Things to check

- `rust-tools/speak-tts/src/main.rs`: after playback it writes empty strings to the cached `.txt` and `.wav` files. This looks like a bug; it should probably `touch` them instead.
- `rust-tools/quickshell-restart/src/main.rs`: it runs `quickshell list` inside the `/proc` scan loop. That is likely much slower than needed; parse once and reuse.
