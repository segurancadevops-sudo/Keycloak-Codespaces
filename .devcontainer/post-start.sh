#!/usr/bin/env bash
set +e

# O GitHub reverte portas públicas para privadas quando o Codespace reinicia.
# Por isso tentamos restaurar a visibilidade pública em cada start.

if [[ -z "${CODESPACE_NAME:-}" ]]; then
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  exit 0
fi

# GITHUB_TOKEN é reconhecido pelo gh dentro do Codespace.
export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

for i in $(seq 1 20); do
  gh codespace ports visibility 8080:public \
    -c "${CODESPACE_NAME}" >/dev/null 2>&1 && exit 0
  sleep 2
done

exit 0
