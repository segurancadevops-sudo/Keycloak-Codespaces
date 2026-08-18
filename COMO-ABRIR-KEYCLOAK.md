# Keycloak Training Academy

## Para o aluno

Depois que o GitHub Codespace estiver pronto, execute:

```bash
./scripts/iniciar-keycloak.sh
```

O navegador somente e liberado depois dos testes automaticos.

O bootstrap verifica:

1. Docker Engine
2. container Keycloak
3. realm `master`
4. issuer OIDC
5. autenticacao do administrador
6. acesso a Admin REST API
7. configuracao do `security-admin-console`
8. visibilidade publica da porta 8080
9. URL externa do Codespaces
10. CORS do endpoint `/protocol/openid-connect/token`

## Acesso

O proprio script mostra a URL correta:

```text
https://NOME-DO-CODESPACE-8080.app.github.dev/admin/
```

No navegador do aluno nao deve ser usado `localhost:8080`.

Tambem nao se deve acrescentar `:8080` ao final de `app.github.dev`.

## Se ocorrer erro

```bash
./scripts/diagnosticar-abertura.sh
```

Para repetir somente os testes:

```bash
./scripts/validar-keycloak.sh
```

## Observacao de seguranca

Este ambiente e descartavel e destinado exclusivamente ao treinamento.

A porta 8080 e tornada publica para evitar a camada de autenticacao da porta
privada do Codespaces durante o fluxo do Admin Console. Portanto, nao coloque
dados reais, segredos reais ou credenciais de producao neste laboratorio.
