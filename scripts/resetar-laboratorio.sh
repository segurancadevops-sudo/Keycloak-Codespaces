#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker rm -f keycloak >/dev/null 2>&1 || true
"${DIR}/iniciar-keycloak.sh"
