#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker rm -f keycloak >/dev/null 2>&1 || true
"${SCRIPT_DIR}/iniciar-keycloak.sh"
