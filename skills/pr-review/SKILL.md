---
name: pr-review
description: Use quando for revisar código — um PR, um diff, uma branch ou um trecho que alguém pediu para olhar. Conduz a revisão por camadas (correção, segurança, design, testes, legibilidade), exige verificar cada achado antes de reportar, classifica por severidade (bloqueia / deveria corrigir / nit) e escreve o feedback com arquivo, linha e correção sugerida.
---

# PR Review

Revisão útil encontra o bug que passaria e ignora o resto. Revisão inútil enche o PR de
comentários de estilo e deixa o `SELECT *` sem `WHERE` passar.

## Quando usar

- Alguém pediu review de um PR, branch ou diff
- Antes de você mesmo abrir um PR (auto-revisão)
- Ao herdar mudança de outra pessoa/agente e precisar decidir se confia

**Não use quando:** o objetivo é escrever o código (aí é implementação), ou provar que funciona
(aí é `verification-before-completion`).

## Antes de comentar qualquer coisa

### 1. Descubra a intenção

Revisar sem saber o objetivo produz comentário fora de contexto. Leia, nesta ordem: descrição do
PR, issue linkada, mensagens de commit. Se nada disso explica **por que** a mudança existe,
esse já é o primeiro comentário.

```bash
git diff main...HEAD --stat        # tamanho e escopo
git log main..HEAD --oneline       # a história que o autor conta
git diff main...HEAD               # a mudança
```

### 2. Leia o arquivo inteiro, não só o diff

O diff mostra o que mudou; o bug mora na interação com o que **não** mudou. Um `return` novo pode
pular o `finally` que já existia. Abra os arquivos tocados por inteiro.

### 3. Reconstrua o fluxo

Para cada função alterada, pergunte: quem chama isso? o que acontece com entrada vazia, nula,
enorme, concorrente? o que acontece se falhar no meio?

## As camadas, em ordem de prioridade

Suba na ordem. Não gaste atenção em nomes de variável enquanto houver risco de perda de dados.

### 1. Correção — isso faz o que promete?

- Off-by-one, `<` vs `<=`, limite de coleção vazia
- `null`/`None`/`undefined` em caminho novo
- Condição invertida, `and`/`or` trocados, negação em cadeia
- Estado mutável compartilhado; corrida entre requests; ordem de operações
- Erro engolido: `except: pass`, `catch {}`, `.catch(() => {})`
- Transação que não faz rollback no caminho de erro
- Migração sem volta, ou que roda antes do código que a suporta

### 2. Segurança — o que um usuário mal-intencionado faz com isso?

- Entrada usada sem validação em query, path, comando, template
- Autorização ausente: o endpoint checa **quem é**, mas checa se **pode**?
- IDOR: o id vem do cliente e ninguém confere o dono
- Segredo em código, log ou mensagem de erro
- Dado sensível serializado por falta de `response_model`/DTO
- Dependência nova: é conhecida? mantida? precisa mesmo?

### 3. Design — isso vai doer daqui a seis meses?

- A mudança cabe onde foi posta, ou vaza regra de negócio para a camada errada?
- Duplicou lógica que já existe no projeto? (procure antes de afirmar)
- Abstração criada para um caso só — é cedo demais?
- Acoplamento novo entre módulos que não se conheciam
- Contrato público alterado sem versionamento

### 4. Testes — o teste falharia se o código estivesse errado?

- O caminho novo está coberto, ou só o feliz?
- O teste testa comportamento ou espelha a implementação?
- Assert vazio, mock que devolve o que o teste quer ouvir, teste sem assert
- Caso de borda que o próprio diff sugere e ninguém testou

### 5. Legibilidade — só depois de tudo acima

- Nome que mente sobre o que a coisa faz
- Função que faz três coisas
- Comentário explicando **o quê** em vez de **por quê**
- Complexidade acidental: aninhamento profundo, flag booleana de parâmetro

## Verifique antes de reportar

**Todo achado é uma hipótese até você confirmar.** Falso positivo custa a confiança do autor e o
tempo dele. Antes de escrever o comentário:

1. Releia o código em volta — a validação pode estar no caller, no middleware, no decorator
2. Procure no repo: `grep` pela função, pelo padrão, pelo teste que cobriria aquilo
3. Se possível, prove: rode o teste, execute o trecho, escreva o caso que quebra

Se não conseguiu confirmar, **diga isso** em vez de afirmar: "não achei onde `user_id` é
validado — está em outro lugar?" é honesto e igualmente útil.

## Severidade — classifique tudo

| Rótulo | Significa | Exemplo |
|---|---|---|
| 🔴 **Bloqueia** | Não pode entrar assim | perda de dados, falha de auth, quebra de contrato |
| 🟡 **Deveria corrigir** | Entra, mas gera dívida real | falta teste do caminho de erro, N+1 em rota quente |
| 🔵 **Nit** | Preferência, opcional | nome, ordem de import, comentário |

Sem rótulo, o autor não sabe o que é obrigatório e trata tudo como igual — ou ignora tudo.

## Como escrever o comentário

Quatro partes: **onde**, **o que**, **por que importa**, **o que fazer**.

```markdown
🔴 `app/api/routers/orders.py:48` — o pedido é buscado por id sem conferir o dono.

Qualquer usuário autenticado consegue ler o pedido de outro trocando o id na URL (IDOR).

Sugestão: filtrar na consulta em vez de só buscar —
`db.query(Order).filter_by(id=order_id, user_id=current_user.id).one_or_none()`
e devolver 404 (não 403) quando não achar, para não vazar existência.
```

- **Sugira, não reescreva o PR.** Se sua sugestão vira uma refatoração de 200 linhas, o comentário certo é "vamos conversar sobre a abordagem", não um patch.
- **Pergunte quando não souber.** "Isso é intencional?" evita o comentário arrogante e errado.
- **Elogie o que merece**, uma linha. Revisão só com defeito treina o autor a evitar você.
- **Ataque o código, nunca a pessoa.** "essa função faz X" e não "você não entendeu Y".

## O que NÃO comentar

- Estilo que o linter/formatter resolve — configure a ferramenta, não o humano
- Preferência pessoal sem argumento técnico ("eu faria diferente")
- Código pré-existente que o PR só tocou de raspão (abra issue separada)
- Reescrita completa da abordagem em um comentário de linha — isso é conversa, não review
- Repetir o mesmo ponto em 8 lugares: comente uma vez e diga "mesmo caso em outros N pontos"

## Formato do parecer

```markdown
## Review — <título do PR>

**Resumo:** <o que a mudança faz, em uma frase — provando que você entendeu>
**Veredito:** aprovar / aprovar com ressalvas / precisa de mudanças

### 🔴 Bloqueia (2)
1. `orders.py:48` — IDOR na busca de pedido. <detalhe + sugestão>
2. `migrations/007.py:12` — migration sem rollback e sem índice; trava a tabela em produção.

### 🟡 Deveria corrigir (1)
3. `orders.py:73` — consulta em loop gera N+1. `selectinload(Order.items)` resolve.

### 🔵 Nits (2)
4. `schemas.py:19` — `data` não diz nada; `order_payload`?

### Verificado
- `pytest tests/test_orders.py` → 14 passed
- Não consegui testar o webhook (sem credencial de sandbox)

### Bom
- A separação do service ficou clara e os testes de borda de `calculate_total` são ótimos.
```

## Armadilhas

- **Revisar o diff sem o contexto.** Fonte número um de comentário errado.
- **Afirmar bug sem confirmar.** Verifique ou pergunte; não chute com tom de certeza.
- **Enterrar o achado grave** no meio de 15 nits. Severidade primeiro, sempre.
- **PR gigante revisado por igual.** Se tem 2.000 linhas, o primeiro comentário é pedir para dividir.
- **Aprovar sem ler os testes.** É onde o "funciona" costuma ser mentira.
- **Confundir "não é como eu faria" com "está errado".**

## Checklist

- [ ] Entendi a intenção antes de comentar
- [ ] Li os arquivos inteiros, não só o diff
- [ ] Passei pelas 5 camadas, na ordem
- [ ] Cada achado foi verificado — ou está marcado como pergunta
- [ ] Tudo classificado por severidade
- [ ] Cada comentário tem arquivo, linha, motivo e sugestão
- [ ] Nenhum comentário sobre o que o linter resolve
- [ ] Veredito explícito no fim
