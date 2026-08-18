#!/usr/bin/env bash
set -Eeuo pipefail

fail() { printf '\n[ERRO] %s\n' "$*" >&2; exit 1; }
ok()   { printf '\n[OK] %s\n' "$*"; }
info() { printf '\n[INFO] %s\n' "$*"; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || fail "Execute dentro do repositorio Keycloak-Codespaces."

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

[[ -f scripts/iniciar-keycloak.sh ]] \
  || fail "Arquivo scripts/iniciar-keycloak.sh nao encontrado."

info "Atualizando branch main..."
git pull --ff-only origin main

BACKUP="scripts/iniciar-keycloak.sh.backup-$(date +%Y%m%d-%H%M%S)"
cp scripts/iniciar-keycloak.sh "$BACKUP"
echo "Backup: $BACKUP"

python3 <<'PY'
from pathlib import Path

path = Path("scripts/iniciar-keycloak.sh")
text = path.read_text(encoding="utf-8")

start_marker = "# Em Codespaces cada aluno recebe um hostname diferente."
end_marker = 'CLIENT_CHECK="$('

start = text.find(start_marker)
end = text.find(end_marker, start)

if start == -1 or end == -1:
    raise SystemExit("[ERRO] Nao foi possivel localizar o bloco antigo para correcao.")

replacement = '''# Em Codespaces cada aluno recebe um hostname diferente.
# Montamos os valores JSON com printf para evitar problemas de escape de aspas.
REDIRECT_SPEC="$(printf 'redirectUris=[\"%s\",\"/admin/master/console/*\"]' "$ADMIN_REDIRECT")"
ORIGIN_SPEC="$(printf 'webOrigins=[\"%s\"]' "$PUBLIC_URL")"

echo "[INFO] Redirects que serao aplicados:"
echo "       $REDIRECT_SPEC"
echo "[INFO] Web Origin que sera aplicada:"
echo "       $ORIGIN_SPEC"

docker exec "$CONTAINER" \
  /opt/keycloak/bin/kcadm.sh update "clients/${CLIENT_ID}" \
  -r master \
  -s "$REDIRECT_SPEC" \
  -s "$ORIGIN_SPEC" >/dev/null \
  || fatal "Nao foi possivel ajustar o security-admin-console."

'''

new_text = text[:start] + replacement + text[end:]
path.write_text(new_text, encoding="utf-8")
print("[OK] Bloco security-admin-console corrigido.")
PY

chmod +x scripts/iniciar-keycloak.sh

info "Validando sintaxe..."
bash -n scripts/iniciar-keycloak.sh \
  || fail "O script corrigido possui erro de sintaxe."

ok "Sintaxe valida."

echo
echo "Trecho corrigido:"
echo "------------------------------------------------------------"
grep -n -A18 -B4 'REDIRECT_SPEC=' scripts/iniciar-keycloak.sh
echo "------------------------------------------------------------"

git add scripts/iniciar-keycloak.sh

if git diff --cached --quiet; then
  echo
  echo "[INFO] Nenhuma alteracao nova para commit."
else
  git commit -m "Corrige JSON do security-admin-console no bootstrap"
fi

info "Enviando para GitHub..."
git push origin main

echo
echo "============================================================"
echo " CORRECAO SINCRONIZADA"
echo "============================================================"
echo
echo "O erro de parse JSON foi corrigido."
echo
echo "Agora exclua o Codespace de teste e crie outro NOVO."
echo "Depois execute:"
echo
echo "  ./scripts/iniciar-keycloak.sh"
echo
echo "No passo [6/9], o esperado e:"
echo
echo "  [OK] security-admin-console configurado para este Codespace."
echo
echo "============================================================"
