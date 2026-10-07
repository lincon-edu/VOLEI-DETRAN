# 🏐 Vôlei DETRAN

Aplicação web para gerenciamento de uma lista de jogadores e rotação de
partidas de vôlei.

O projeto foi criado para facilitar a organização dos jogadores,
controle de presença, formação dos times, fila de espera, rotação da
quadra e acompanhamento de vitórias e partidas.

A aplicação foi desenvolvida para funcionar diretamente no navegador e
utiliza o **Supabase** para autenticação, persistência dos dados e
sincronização entre os dispositivos.

------------------------------------------------------------------------

## 📋 Funcionalidades atuais

### 👥 Lista de jogadores

-   Lista com até **40 jogadores**.
-   Limite de **30 jogadores confirmados**.
-   Cada jogador possui sexo:
    -   `M` --- Masculino
    -   `F` --- Feminino
-   Controle de status através da flag do jogador:
    -   🟢 **Confirmado**
    -   🔴 **Ausente**
    -   🟡 **Pendente**
-   Somente jogadores **confirmados** podem participar da partida.
-   Jogadores ausentes e pendentes permanecem cadastrados, mas não podem
    entrar na quadra.
-   Um jogador que chega posteriormente pode ser alterado de **Pendente
    → Confirmado** e entrar na fila.

### 🏐 Formação dos times

A aplicação possui dois times:

-   **Time A**
-   **Time B**

Cada time possui atualmente **4 jogadores**.

A formação respeita a regra de mulheres:

-   Se a quantidade de mulheres confirmadas for **menor que 50%** do
    total de confirmados:
    -   mínimo de **1 mulher por time**.
-   Se a quantidade de mulheres confirmadas for **igual ou superior a
    50%**:
    -   mínimo de **2 mulheres por time**.

A aplicação verifica primeiro a necessidade de mulheres e depois utiliza
a ordem da fila para preencher as demais posições.

### ⏳ Fila de espera

A fila representa os próximos jogadores que entrarão na quadra.

O administrador pode:

-   subir um jogador;
-   descer um jogador;
-   remover um jogador da lista;
-   visualizar a posição atual;
-   visualizar quantas vezes o jogador ficou esperando.

A **ordem manual da fila é respeitada na hora de montar os próximos
times**, sempre obedecendo primeiro à regra de quantidade mínima de
mulheres.

Exemplo:

``` text
1º Rafael
2º João
3º Pedro
4º Tiago
5º Marcos
```

Se Rafael for movido da posição 17 para a posição 1, ele passa a ser
considerado como o primeiro jogador da fila na próxima rotação,
respeitando a regra de mulheres.

### 🔄 Rotação

A regra atual de rotação é:

1.  Um time vence uma partida.
2.  O time vencedor permanece na quadra.
3.  O time perdedor sai.
4.  A fila é utilizada para completar o time que saiu.
5.  Se o mesmo time vencer **duas partidas consecutivas**, os **dois
    times saem da quadra**.
6.  Os próximos jogadores da fila entram respeitando:
    -   regra de mulheres;
    -   ordem atual da fila.

### 📊 Resenha

A aba **Resenha** apresenta o ranking dos jogadores com:

-   posição;
-   nome;
-   quantidade de jogos;
-   quantidade de vitórias;
-   percentual de aproveitamento.

### 🔐 Autenticação

O acesso administrativo utiliza **Supabase Authentication**.

Não existe mais uma lista de usuários e senhas administrativos gravada
diretamente no código da aplicação.

O administrador precisa estar cadastrado no:

**Supabase → Authentication → Users**

Usuários não autenticados podem acompanhar as informações públicas da
partida, enquanto as operações administrativas ficam disponíveis somente
para usuários autenticados.

### ☁️ Sincronização

Os dados são armazenados no Supabase para permitir que:

-   o administrador altere a partida pelo celular ou computador;
-   outros celulares acompanhem a mesma partida;
-   as alterações sejam persistidas;
-   o estado do jogo permaneça disponível após atualizar a página.

------------------------------------------------------------------------

# 🗂️ Estrutura do projeto

Uma estrutura recomendada para o GitHub:

``` text
VOLEI-DETRAN/
│
├── index.html
├── README.md
├── VOLEI-DETRAN-SUPABASE.sql
└── LICENSE
```

O `index.html` é a aplicação principal.

Os arquivos SQL são utilizados para criação e atualização da estrutura
do banco de dados no Supabase.

------------------------------------------------------------------------

# 🛠️ Tecnologias utilizadas

-   HTML5
-   CSS3
-   JavaScript
-   Supabase
    -   Database
    -   Authentication
    -   Realtime
-   GitHub Pages

Não é necessário um servidor Node.js para executar a aplicação.

A aplicação pode ser publicada como uma página estática.

------------------------------------------------------------------------

# 🚀 Configuração

## 1. Criar o projeto no Supabase

Crie um projeto no Supabase.

Depois execute o SQL de estrutura inicial:

``` text
VOLEI-DETRAN-SUPABASE.sql
```

no:

**Supabase → SQL Editor**

------------------------------------------------------------------------

## 2. Criar os administradores

No Supabase:

``` text
Authentication
    ↓
Users
    ↓
Add user
```

Cadastre o e-mail e a senha dos administradores.

As credenciais não devem ser colocadas no README nem armazenadas
diretamente no JavaScript.

------------------------------------------------------------------------

## 3. Configurar a aplicação

No `index.html`, configure o projeto Supabase utilizando:

``` javascript
const SUPABASE_URL = 'SUA_URL';
const SUPABASE_KEY = 'SUA_CHAVE_PUBLICAVEL';
```

A chave utilizada no frontend deve ser a chave pública/publishable do
Supabase.

**Nunca coloque uma `service_role key` no HTML ou em qualquer arquivo
publicado no GitHub.**

------------------------------------------------------------------------

## 4. Publicar no GitHub Pages

O arquivo principal deve estar na raiz do repositório com o nome:

``` text
index.html
```

Depois:

``` text
GitHub
→ Settings
→ Pages
→ Deploy from branch
→ main
→ / (root)
```

Após a publicação, o GitHub Pages disponibilizará a aplicação através da
URL do repositório.

------------------------------------------------------------------------

# 🗄️ Banco de dados

A aplicação utiliza o Supabase como backend.

Entre os dados persistidos estão:

### Jogadores

Informações relacionadas a:

-   nome;
-   sexo;
-   status;
-   partidas;
-   vitórias;
-   tempo/contador de espera;
-   ordem da fila.

### Estado do jogo

Informações relacionadas a:

-   jogo iniciado;
-   vitórias consecutivas do Time A;
-   vitórias consecutivas do Time B;
-   jogadores do Time A;
-   jogadores do Time B;
-   jogadores na fila.

------------------------------------------------------------------------

# 🔒 Segurança

O projeto utiliza dois níveis de acesso:

### Usuário público

Pode visualizar:

-   lista;
-   times;
-   fila;
-   ranking.

### Usuário autenticado

Pode realizar operações administrativas, como:

-   alterar presença;
-   adicionar jogador;
-   remover jogador;
-   alterar a fila;
-   iniciar partida;
-   registrar vencedor;
-   reiniciar a partida.

As políticas **RLS (Row Level Security)** do Supabase devem ser mantidas
habilitadas.

> Nunca utilize uma `service_role key` no frontend.

------------------------------------------------------------------------

# 🔄 Reiniciar partida

A função **Reiniciar** encerra a partida atual e restaura o estado
inicial do jogo.

Também limpa as estatísticas da Resenha:

``` text
Partidas = 0
Vitórias = 0
Espera = 0
Vitórias consecutivas = 0
```

Os jogadores continuam cadastrados na lista.

------------------------------------------------------------------------

# 📌 Regras atuais resumidas
```text
  Regra                                                 Valor
  --------------------------------- -------------------------
  Máximo de jogadores cadastrados                          40
  Máximo de confirmados                                    30
  Jogadores por time                                        4
  Mínimo de mulheres por time                               1
  Mulheres ≥ 50%                                   2 por time
  Jogadores ausentes na quadra                            Não
  Jogadores pendentes na quadra                           Não
  Jogadores confirmados na quadra                         Sim
  Vitória consecutiva                 Time vencedor permanece
  2 vitórias consecutivas                 Ambos os times saem
```
------------------------------------------------------------------------

# 🧭 Próximas melhorias

O projeto continuará evoluindo.

Algumas funcionalidades planejadas para futuras versões:

### ⚙️ Configurações do jogo pelo ADM

Criar uma área de configurações onde o administrador possa alterar
diretamente pela aplicação:

-   **Quantidade de jogadores por time**
    -   Ex.: 4, 5, 6 etc.
-   **Quantidade mínima de mulheres por time**
    -   Ex.: 1, 2 etc.
-   **Regra automática de mulheres**
    -   Definir se a regra de 50% continuará sendo utilizada.
-   **Regra de rotação após duas vitórias**
    -   Criar uma flag para determinar o comportamento após o time
        vencer duas partidas consecutivas.

### 🏆 Próxima regra planejada

Uma das opções futuras será:

> **Quando um time vencer duas partidas consecutivas e sair da quadra,
> ele poderá ser colocado como o próximo time a entrar novamente.**

Essa regra deverá ser configurável pelo ADM através de uma flag,
permitindo escolher entre:

``` text
☐ Time que venceu duas vezes é o próximo a entrar
```

ou manter o comportamento padrão da fila.

### 🎛️ Configuração geral

A ideia é futuramente transformar as regras atualmente fixas no código
em configurações administráveis:

``` text
Configurações da partida

Jogadores por time:       [ 4 ]

Mínimo de mulheres:       [ 1 ]

Mulheres ≥ 50%:           [ 2 ]

Time que vence 2x volta
como próximo:             [ OFF ]
```

Assim, o administrador poderá adaptar a aplicação para diferentes
formatos de partidas sem precisar alterar o código.

------------------------------------------------------------------------

# 📜 Histórico do projeto

O projeto começou como uma aplicação HTML/JavaScript local para
controlar a rotação de jogadores.

Posteriormente foram adicionados:

1.  Persistência no Supabase.
2.  Sincronização entre dispositivos.
3.  Autenticação administrativa.
4.  Ranking e histórico de partidas.
5.  Controle de status dos jogadores.
6.  Suporte para até 40 jogadores cadastrados.
7.  Limite de 30 jogadores confirmados.
8.  Controle manual da fila de espera.
9.  Regras de composição dos times considerando a quantidade de
    mulheres.

------------------------------------------------------------------------

# 👨‍💻 Autor

Projeto desenvolvido por **Lincon**.

**Vôlei DETRAN --- Sistema de organização e rotação de partidas de
vôlei.**

------------------------------------------------------------------------

## ⭐ Contribuições

Sugestões, melhorias e correções são bem-vindas.

Antes de alterar a lógica de rotação, preserve as regras de negócio
existentes e descreva claramente a alteração proposta.

------------------------------------------------------------------------

## 📄 Licença

Defina aqui a licença desejada para o projeto antes de torná-lo público.
