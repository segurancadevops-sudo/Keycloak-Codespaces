# Laboratorio 03 - Realm, Usuario, Grupo e Role

> Laboratorio pratico da Keycloak Training Academy.

# Laboratório 03 - Realm, Usuário, Grupo e Role

Neste laboratório você irá administrar os principais componentes do Keycloak.

## Objetivo

Ao final você será capaz de:

- criar um Realm;
- criar um Grupo;
- criar uma Role;
- criar um Usuário;
- associar o usuário ao grupo;
- associar permissões;
- validar a configuração.

> O Keycloak deve estar em execução antes de iniciar este laboratório.

---

# Passo 1 - Criar o Realm

Acesse o console administrativo do Keycloak.

Crie um novo Realm com o nome:

`semfaz-lab`

Depois confirme se o Realm aparece selecionado no canto superior esquerdo.

## Conceito

Um Realm é um ambiente lógico que organiza usuários, grupos, roles, clients e configurações de autenticação.

---

# Passo 2 - Criar Grupo e Role

No Realm `semfaz-lab`:

## Grupo

Crie o grupo:

`Auditores`

## Role

Crie a Realm Role:

`consulta-tributaria`

Depois associe a Role `consulta-tributaria` ao grupo `Auditores`.

---

# Passo 3 - Criar Usuário e Associar Permissões

Crie o usuário:

`joao.silva`

Defina uma senha para o usuário.

Depois associe o usuário ao grupo:

`Auditores`

A estrutura deverá ficar assim:

`joao.silva -> Auditores -> consulta-tributaria`

---

# Passo 4 - Validar a Configuração

Abra o usuário `joao.silva`.

Acesse:

**Role Mapping**

Confira as roles efetivas do usuário.

A Role abaixo deverá estar disponível:

`consulta-tributaria`

Se estiver presente, a associação foi realizada corretamente.

---

# Laboratório concluído

Você criou e relacionou:

- Realm;
- Grupo;
- Role;
- Usuário.

Também validou a herança de permissões.

## Próximo laboratório

No próximo laboratório vamos criar um Client OpenID Connect e entender como uma aplicação se integra ao Keycloak.

