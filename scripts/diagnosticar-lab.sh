#!/usr/bin/env bash
set +e
PASS=0; FAIL=0; WARN=0
pass(){ echo "[OK] $*"; PASS=$((PASS+1)); }
fail(){ echo "[ERRO] $*"; FAIL=$((FAIL+1)); }
warn(){ echo "[AVISO] $*"; WARN=$((WARN+1)); }

echo "============================================================"
echo " DIAGNÓSTICO - KEYCLOAK TRAINING ACADEMY"
echo "============================================================"

if [[ -n "${CODESPACE_NAME:-}" ]]; then pass "Codespace: ${CODESPACE_NAME}"; else warn "CODESPACE_NAME ausente."; fi

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  echo "Sistema: ${PRETTY_NAME:-desconhecido}"
  [[ "${VERSION_CODENAME:-}" == "noble" ]] && pass "Ubuntu 24.04 noble." || warn "Codename atual: ${VERSION_CODENAME:-desconhecido}."
fi

if [[ -f .devcontainer/devcontainer.json ]]; then
  pass "devcontainer.json encontrado."
  python3 - <<'PY' >/dev/null 2>&1
import json
json.load(open('.devcontainer/devcontainer.json'))
PY
  [[ $? -eq 0 ]] && pass "devcontainer.json válido." || fail "devcontainer.json inválido."
  grep -q 'base:noble' .devcontainer/devcontainer.json && pass "Base fixada em noble." || fail "Base não está fixada em noble."
  grep -q '"moby": false' .devcontainer/devcontainer.json && pass "moby=false configurado." || fail "moby=false ausente."
else
  fail "devcontainer.json não encontrado."
fi

if command -v docker >/dev/null 2>&1; then
  pass "Docker CLI: $(docker --version 2>/dev/null)"
  docker info >/dev/null 2>&1 && pass "Docker Engine respondendo." || fail "Docker Engine não responde."
else
  fail "docker: command not found"
fi

command -v curl >/dev/null 2>&1 && pass "curl disponível." || fail "curl não encontrado."

if command -v docker >/dev/null 2>&1 && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx keycloak; then
  pass "Container keycloak existe."
else
  warn "Container keycloak ainda não existe."
fi

curl -fsS http://localhost:8080/realms/master >/dev/null 2>&1 && pass "Keycloak responde em localhost:8080." || warn "Keycloak ainda não responde em localhost:8080."

if [[ -n "${CODESPACE_NAME:-}" ]]; then
  echo "URL esperada: https://${CODESPACE_NAME}-8080.app.github.dev"
fi

echo "============================================================"
echo "RESULTADO: $PASS OK | $WARN AVISOS | $FAIL ERROS"
echo "============================================================"

[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
