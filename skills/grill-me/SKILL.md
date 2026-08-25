---
name: grill-me
description: Use quando o pedido do usuário for vago, amplo ou tiver mais de uma interpretação razoável, e sempre que ele disser "grill me", "me interrogue" ou "me questione antes". Faz o Claude interrogar o usuário sobre objetivo, restrições, decisões pendentes e definição de pronto ANTES de escrever qualquer código, e só executar depois de um brief confirmado.
---

# Grill Me

Ideia mal explicada gera código bonito que resolve o problema errado. Esta skill inverte a
ordem: **primeiro o interrogatório, depois a execução.**

## Quando usar

- O pedido cabe em uma frase mas implicaria dias de trabalho ("refaz o dashboard", "melhora a API")
- Existem duas ou mais implementações defensáveis e elas divergem muito em custo
- O usuário pediu explicitamente para ser questionado
- O pedido menciona um resultado ("mais rápido", "mais bonito", "mais seguro") sem número, baseline ou critério

**Não use quando:** o pedido é mecânico e verificável (renomear, corrigir um erro apontado,
rodar um teste), ou quando o usuário já respondeu essas perguntas nesta conversa. Perguntar o
óbvio é tão ruim quanto não perguntar nada.

## Regra de ouro

**Pesquise antes de perguntar.** Toda pergunta que o repositório responde é uma pergunta
proibida. Antes da primeira rodada:

1. Leia `CLAUDE.md`, `README.md` e a estrutura de pastas
2. Procure o código que o pedido toca (`grep`/`glob` pelos termos citados)
3. Veja como problemas parecidos já foram resolvidos no projeto

Só então pergunte — e pergunte apenas o que **não dá para descobrir sozinho** e o que **muda o
que você vai fazer**.

## Os quatro eixos

Toda rodada de perguntas cobre estes eixos. Se um já estiver claro, pule.

### 1. Objetivo — que problema real isso resolve?

Não "o que você quer que eu faça", mas "o que está quebrado hoje / o que fica possível depois".

- Quem é afetado e com que frequência?
- Como você sabe hoje que isso é um problema? (número, print, reclamação)
- O que acontece se não fizermos nada?

### 2. Restrições — o que não pode mudar?

- Stack, versões, dependências proibidas
- Compatibilidade: quebrar API pública? migração de dados? downtime?
- Prazo e orçamento de esforço (uma hora? uma semana?)
- Padrões do projeto que devo seguir mesmo discordando

### 3. Decisões pendentes — onde há mais de um caminho?

Liste as bifurcações reais que você encontrou lendo o código e **traga uma recomendação** em
cada uma. Pergunta sem opção é transferência de trabalho; pergunta com opções e uma
recomendação é decisão informada.

### 4. Definição de pronto — como verificamos?

- Qual comando/tela prova que funcionou?
- Precisa de teste automatizado? De qual tipo?
- Entra no escopo: doc, migration, changelog, deploy?
- O que está **fora** do escopo desta rodada?

## Como conduzir

1. **Agrupe.** Use `AskUserQuestion` com até 4 perguntas de uma vez, uma por eixo. Não faça
   pingue-pongue de uma pergunta por mensagem.
2. **Ofereça opções, não campos em branco.** Cada pergunta vem com 2–4 alternativas concretas;
   a recomendada em primeiro, marcada com "(Recomendado)".
3. **Máximo 3 rodadas.** Se depois da terceira ainda houver ambiguidade, escolha a interpretação
   mais provável, **declare a suposição em voz alta** e siga. Interrogatório infinito é outra
   forma de não entregar.
4. **Pare cedo se der.** Assim que o brief fecha, pare de perguntar. Uma rodada costuma bastar.

## Brief de fechamento

Antes de tocar em qualquer arquivo, escreva o brief e peça o "ok". Formato:

```markdown
## Brief — <título curto>

**Objetivo:** <uma frase: o problema que some>
**Escopo:** <o que será feito>
**Fora de escopo:** <o que explicitamente não será feito agora>

**Restrições**
- <restrição> 
- <restrição>

**Decisões**
| Questão | Escolha | Motivo |
|---|---|---|
| <bifurcação> | <opção escolhida> | <razão> |

**Pronto quando**
- [ ] <critério verificável>
- [ ] <critério verificável>

**Suposições** (siga em frente se não houver correção)
- <suposição>
```

Depois do "ok", execute o brief — não o pedido original. Se durante a execução aparecer uma
decisão que não estava no brief e que muda o resultado, pare e pergunte; se for reversível e
menor, decida, anote e siga.

## Armadilhas

- **Perguntar o que está no repo.** Destrói a confiança. Leia primeiro.
- **Perguntas abstratas.** "Quais são seus requisitos não-funcionais?" não gera resposta útil.
  Pergunte "essa tela pode demorar 2s para carregar ou precisa ser instantânea?".
- **Interrogar tarefa trivial.** Se dá para fazer em 5 minutos e é reversível, faça.
- **Aceitar "tanto faz" e travar.** "Tanto faz" é uma resposta válida: escolha, registre como
  suposição e siga.
- **Brief que vira contrato rígido.** Ele orienta; se a realidade do código contradisser, avise
  e ajuste em vez de entregar algo errado por fidelidade ao documento.

## Checklist

- [ ] Li o repositório antes de perguntar
- [ ] Perguntas agrupadas em uma única rodada, com opções e recomendação
- [ ] Os quatro eixos cobertos (ou explicitamente dispensados)
- [ ] Brief escrito e confirmado antes do primeiro arquivo alterado
- [ ] Critérios de "pronto" são verificáveis por comando ou observação, não por opinião
