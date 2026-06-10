#!/usr/bin/env bash

set -euo pipefail

# Qt 6 may try to register the same portal app connection twice for this
# layer-shell process. It is harmless, but it pollutes Quickshell logs.
if [[ -n "${QT_LOGGING_RULES:-}" ]]; then
  export QT_LOGGING_RULES="${QT_LOGGING_RULES};qt.qpa.services.warning=false"
else
  export QT_LOGGING_RULES="qt.qpa.services.warning=false"
fi

exec quickshell --no-duplicate
