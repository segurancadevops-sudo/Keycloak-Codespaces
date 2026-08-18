#!/usr/bin/env bash
set -euo pipefail
docker logs -f --tail 100 keycloak
