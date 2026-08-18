#!/usr/bin/env bash
set -euo pipefail
docker logs -f --tail 150 keycloak
