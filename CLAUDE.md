# CLAUDE.md

Guia para trabalhar neste repositório. Leia antes de criar ou editar qualquer skill.

## O que é este repositório

Uma **biblioteca de Agent Skills** para Claude Code. Ele não é uma aplicação: não há build,
não há runtime, não há dependências. O produto entregue é o conteúdo em `skills/`, feito
para ser copiado (ou linkado) para o `.claude/skills/` de outros projetos ou para o
`~/.claude/skills/` global.

Consequência prática: **cada skill precisa ser autocontida e portátil**. Nunca assuma caminhos,
variáveis de ambiente ou arquivos deste repositório em tempo de execução — a skill vai rodar
dentro do projeto de outra pessoa.

## Estrutura

```
skilss/
├── CLAUDE.md                  # este arquivo
├── README.md                  # catálogo das skills + como instalar
├── .claude-plugin/
│   ├── marketplace.json       # torna o repo um marketplace (/plugin marketplace add)
│   └── plugin.json            # manifesto do plugin "dev-skills" (raiz = plugin)
├── get.ps1 / get.sh           # instalador remoto (baixa do GitHub, sem clone)
├── install.ps1 / install.sh   # instalador local (a partir do clone)
├── templates/
│   └── SKILL.template.md      # ponto de partida para uma skill nova
└── skills/
    └── <nome-da-skill>/
        ├── SKILL.md           # obrigatório
        ├── references/        # opcional: docs longos carregados sob demanda
        ├── scripts/           # opcional: scripts executáveis
        └── assets/            # opcional: templates, exemplos, arquivos de apoio
```

Uma pasta por skill dentro de `skills/`. O nome da pasta **é** o nome da skill.

### Duas formas de distribuição, uma só pasta

O repo é ao mesmo tempo um **marketplace de plugin** e uma **fonte de skills avulsas**, e as duas
leem exatamente a mesma `skills/`:

| Via | Comando | Granularidade |
|---|---|---|
| Marketplace | `/plugin marketplace add isranetoo/skilss` + `/plugin install dev-skills@isranetoo-skills` | pacote inteiro |
| Instalador remoto | `irm .../get.ps1 \| iex` | skill a skill |

Consequência ao adicionar uma skill: basta criar a pasta em `skills/`. **Não** é preciso registrar
nada no `plugin.json` — o Claude Code descobre as skills do plugin automaticamente. Só suba a
`version` no `plugin.json` e no `marketplace.json` quando publicar mudanças relevantes.

Arquivos de componente de plugin (`skills/`, `commands/`, `agents/`) ficam na **raiz** do repo,
nunca dentro de `.claude-plugin/` — lá vão só os dois manifestos JSON.

## Anatomia de uma SKILL.md

```markdown
---
name: nome-da-skill
description: Use quando <gatilho concreto>. Faz <o que faz>. Cobre <escopo>.
allowed-tools: Read, Grep, Glob, Bash   # opcional; omita para permitir tudo
---

# Nome da Skill

## Quando usar
Situações concretas que disparam esta skill (e quando NÃO usar).

## Como fazer
Passos imperativos, na ordem. Comandos prontos para copiar.

## Referências
- `references/detalhes.md` — carregue só se precisar de X
```

### Regras do frontmatter

| Campo | Obrigatório | Regras |
|---|---|---|
| `name` | sim | kebab-case, só `a-z0-9-`, ≤ 64 caracteres, **idêntico ao nome da pasta** |
| `description` | sim | ≤ 1024 caracteres, terceira pessoa, começa com o gatilho ("Use quando…") |
| `allowed-tools` | não | lista separada por vírgula; restrinja em skills de leitura/auditoria |

A `description` é o único texto que o Claude vê antes de decidir carregar a skill. Ela é um
**classificador**, não um resumo bonito. Escreva o gatilho com as palavras que o usuário
realmente digita.

- ✅ `Use quando for criar ou revisar endpoints FastAPI — routers, dependências, response_model, status codes e tratamento de erro.`
- ❌ `Ajuda com FastAPI.`

## Como escrever o corpo

- **Imperativo e direto.** "Rode `X`", não "você poderia considerar rodar X".
- **Curto.** Alvo: até ~500 linhas no `SKILL.md`. Detalhe extenso vai para `references/` e é
  citado por caminho relativo, para ser lido só quando necessário (progressive disclosure).
- **Exemplos executáveis.** Prefira um comando ou trecho de código correto a três parágrafos
  explicando o conceito.
- **Sem redundância com o modelo.** Não ensine o que o Claude já sabe (sintaxe básica de Python,
  o que é HTTP). Documente o que é específico: convenções, armadilhas, ordem de passos, decisões.
- **Caminhos relativos à pasta da skill.** `references/x.md`, `scripts/y.py` — nunca caminhos
  absolutos da máquina.
- **Scripts precisam ser portáteis.** Windows é o ambiente primário do autor; se o script for
  `.sh`, garanta equivalente `.ps1` ou use Python.

## Criando uma skill nova

1. `cp templates/SKILL.template.md skills/<nome>/SKILL.md` (crie a pasta antes).
2. Preencha `name` (= nome da pasta) e escreva a `description` **primeiro** — se ela não sair
   clara, o escopo da skill está errado.
3. Escreva o corpo. Se passar de ~500 linhas, quebre em `references/`.
4. Atualize o catálogo no `README.md`.
5. Rode o checklist abaixo.

### Checklist antes de commitar

- [ ] `name` bate exatamente com o nome da pasta
- [ ] `description` diz **quando** usar, não só o que é
- [ ] Nenhum caminho absoluto ou dependência deste repositório
- [ ] Testada de verdade: instalada em um projeto e disparada por um pedido real
- [ ] `README.md` atualizado

## Escopo: uma skill, um trabalho

Skills grandes demais nunca são escolhidas; skills pequenas demais poluem o índice. Regra:
se a `description` precisa de "e também" para cobrir tudo, divida.

- ✅ `fastapi-endpoints`, `fastapi-testing`, `pydantic-models`
- ❌ `fastapi` (tudo sobre FastAPI)
- ❌ `adicionar-um-campo-no-modelo` (específico demais, é uma tarefa)

## Instalando em outro lugar

**Marketplace** (pacote inteiro, dentro do Claude Code):

```
/plugin marketplace add isranetoo/skilss
/plugin install dev-skills@isranetoo-skills
/plugin marketplace update isranetoo-skills     # puxa mudanças depois
```

**Instalador remoto** (skill avulsa, sem clone):

```powershell
$env:SKILLS='grill-me'; irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1 | iex
```

**A partir do clone** (quando você está editando as skills):

```powershell
.\install.ps1 -Global                          # todas
.\install.ps1 -Global -Skills grill-me         # só uma
.\install.ps1 -Target C:\caminho\do\projeto    # em um projeto
```

Nos dois últimos casos o script copia `skills/<nome>` para `<destino>/.claude/skills/<nome>` e o
repo não é mais consultado — por isso a exigência de skills autocontidas.

## Convenções de commit

Um commit por skill quando possível. Mensagem: `skill: <nome> — <o que mudou>`.
Ex.: `skill: fastapi-endpoints — adiciona seção de tratamento de erro`.
