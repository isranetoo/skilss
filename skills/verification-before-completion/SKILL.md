---
name: verification-before-completion
description: Use sempre que estiver prestes a declarar uma tarefa concluída — "pronto", "funcionando", "corrigido", "implementado". Proíbe anunciar sucesso sem evidência executada: exige rodar testes, conferir a saída real, checar cada requisito do pedido e mostrar os logs. Vale também antes de abrir PR ou entregar handoff.
---

# Verification Before Completion

Confiança não prova nada. Resultado verificável prova.

**Regra dura:** você não pode escrever "pronto", "funcionando", "corrigido" ou "implementado"
sem ter, na mesma resposta, a evidência de execução que sustenta a frase.

## Quando usar

- Antes de qualquer mensagem que declare tarefa concluída
- Antes de abrir PR ou pedir revisão
- Antes de passar contexto para outra sessão/agente
- Depois de corrigir um bug reportado — provar que o sintoma sumiu

**Não use quando:** a resposta é conversa, pesquisa ou plano — não há nada a verificar ainda.

## O portão

Antes de declarar pronto, os quatro passos abaixo. Sem exceção, sem pular por parecer óbvio.

### 1. Reler o pedido e listar os requisitos

Volte à mensagem original do usuário — não à sua interpretação dela. Extraia cada exigência,
inclusive as implícitas e as ditas de passagem ("e aproveita para...").

```markdown
| # | Requisito (palavras do usuário) | Status | Evidência |
|---|---|---|---|
| 1 | "endpoint de exclusão" | ✅ | teste `test_delete_user` passa |
| 2 | "só admin pode chamar" | ✅ | `test_delete_requires_admin` retorna 403 |
| 3 | "atualizar o README" | ❌ | não feito |
```

Requisito sem evidência é requisito não cumprido. Um `❌` na tabela significa que a tarefa **não**
está pronta — ou você faz, ou você declara explicitamente que ficou de fora e por quê.

### 2. Executar — não inspecionar

Ler o código e concluir que está certo **não é verificação**. Rode:

```bash
npm test          # ou pytest, go test, cargo test — o comando real do projeto
npm run lint
npm run build     # compila? typecheck passa?
```

Para mudança visível ao usuário, exercite no navegador ou na CLI de verdade. Para API, chame o
endpoint. Para script, execute com entrada real.

Se não existe teste cobrindo o que você mudou, ou você escreve um, ou você executa manualmente e
mostra a saída. "Não tinha teste" não dispensa a prova.

### 3. Ler a saída inteira

O erro costuma estar no meio do log, não no exit code.

- Exit code 0 **não** basta: procure `WARN`, `SKIPPED`, `0 tests ran`, `deprecated`
- Confira o número de testes: 12 passaram de 12? Ou 12 de 47 porque um arquivo nem coletou?
- Um teste que passa sem executar sua mudança não prova nada. Confirme que ele cobre o caminho novo — se em dúvida, quebre o código de propósito e veja o teste falhar
- Confira que você não quebrou o resto: rode a suíte completa, não só o arquivo que tocou

### 4. Apresentar a evidência

Mostre a saída real, recortada no que importa. Não parafraseie.

```markdown
**Verificado**

$ pytest tests/ -q
.......................... 26 passed in 3.41s

$ npm run build
✓ compiled successfully

Requisitos: 3/3 cumpridos (tabela acima).
Não coberto: comportamento com banco offline — sem teste de integração no projeto.
```

## Como falar quando não deu certo

Verificação que falha é informação valiosa, não fracasso a esconder. Reporte com a saída bruta:

```markdown
**Não está pronto.** `pytest` falha em 2 de 26:

FAILED tests/test_users.py::test_delete_requires_admin - assert 200 == 403

A checagem de permissão não está sendo aplicada no router. Investigando.
```

Nunca:
- Declare sucesso e adicione "mas não testei" no fim — isso é declarar sucesso sem evidência
- Diga "deve funcionar", "provavelmente funciona", "está correto pelo que vejo"
- Esconda um teste que falhou por parecer "não relacionado" — cite e explique
- Marque um requisito como feito porque escreveu o código dele

## Se a verificação for impossível

Às vezes não dá: falta credencial, o serviço externo está fora, o ambiente não sobe. Então:

1. **Diga isso explicitamente** — nunca preencha o vazio com confiança
2. Verifique tudo o que **é** possível (typecheck, lint, testes unitários)
3. Escreva o comando exato que o usuário precisa rodar para fechar a lacuna

```markdown
**Parcialmente verificado.** Unitários passam (18/18) e o build compila.
Não consegui testar o envio real de e-mail — falta `SENDGRID_API_KEY` no ambiente.
Para confirmar: `SENDGRID_API_KEY=... pytest tests/test_email.py -v`
```

## Armadilhas

- **Confundir "compilou" com "funciona".** Build passando é o piso, não a prova.
- **Rodar só o teste novo.** Regressão é o modo mais comum de falha.
- **Teste que passa vazio.** `0 tests ran` com exit 0 engana; confira a contagem.
- **Verificar antes da última edição.** Alterou depois de rodar? Rode de novo.
- **Requisito lembrado pela metade.** Releia a mensagem original, não o seu resumo dela.
- **Deixar processo de background rodando** e chamar de ambiente verificado.

## Checklist final

- [ ] Todos os requisitos do pedido original listados e marcados
- [ ] Testes executados **agora**, depois da última alteração
- [ ] Suíte completa, não só o arquivo tocado
- [ ] Saída lida inteira: contagem, warnings, skips
- [ ] Evidência colada na resposta, não parafraseada
- [ ] O que não foi verificado está declarado, com o comando para fechar a lacuna
