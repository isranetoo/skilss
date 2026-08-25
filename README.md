# skilss

Biblioteca pessoal de **Agent Skills** para o Claude Code. Cada skill é autocontida: instale em
qualquer máquina com um comando, sem clonar o repositório.

## Instalação em 1 comando

**Windows (PowerShell)** — todas as skills, global (`~/.claude/skills`):

```powershell
irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1 | iex
```

Só uma skill:

```powershell
$env:SKILLS='grill-me'; irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1 | iex
```

Em um projeto específico, ou sobrescrevendo o que já existe:

```powershell
$env:SKILLS_TARGET='C:\caminho\do\projeto'; $env:SKILLS_FORCE=1
irm https://raw.githubusercontent.com/isranetoo/skilss/main/get.ps1 | iex
```

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/isranetoo/skilss/main/get.sh | bash
curl -fsSL https://raw.githubusercontent.com/isranetoo/skilss/main/get.sh | bash -s -- grill-me
curl -fsSL https://raw.githubusercontent.com/isranetoo/skilss/main/get.sh | bash -s -- --list
```

Depois de instalar, **reinicie o Claude Code** para as skills serem carregadas.

## Catálogo

| Skill | O que faz |
|---|---|
| [`grill-me`](skills/grill-me/) | Interroga você sobre objetivo, restrições, decisões e definição de pronto **antes** de escrever código. Fecha com um brief confirmado. |
| [`verification-before-completion`](skills/verification-before-completion/) | Proíbe dizer "pronto" sem evidência: roda os testes, confere cada requisito e cola a saída real. |
| [`webapp-testing`](skills/webapp-testing/) | Abre o navegador, clica, preenche formulário, lê o console e tira screenshot. Verifica em vez de perguntar "funcionou?". |
| [`web-quality-audit`](skills/web-quality-audit/) | Audita performance, Core Web Vitals, acessibilidade, SEO técnico e mobile. Relatório priorizado por impacto. |
| [`fastapi-endpoints`](skills/fastapi-endpoints/) | Convenções e armadilhas de rotas FastAPI: routers, `response_model`, status codes, erros, async vs sync, paginação. |

## Instalação a partir do clone

Se você já clonou o repo (para editar as skills):

```powershell
.\install.ps1 -Global                    # todas
.\install.ps1 -Global -Skills grill-me   # só uma
.\install.ps1 -Target C:\projeto         # em um projeto
.\install.ps1 -List                      # ver o que existe
```

No Linux/macOS: `./install.sh --global`, `./install.sh --target <pasta>`, `./install.sh --list`.
Adicione `-Force` / `--force` para sobrescrever.

Manual funciona igual: copie `skills/<nome>/` para `.claude/skills/<nome>/`.

## Criando uma skill

Convenções em [`CLAUDE.md`](CLAUDE.md); ponto de partida em
[`templates/SKILL.template.md`](templates/SKILL.template.md).
