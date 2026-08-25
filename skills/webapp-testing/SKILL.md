---
name: webapp-testing
description: Use quando terminar uma mudança de front-end ou full-stack e for preciso provar que o app funciona de verdade — abrir a página no navegador, clicar, preencher formulário, ler erros do console e registrar screenshot. Substitui "acho que funcionou" e "pode testar aí?" por verificação executada pelo próprio Claude.
---

# Webapp Testing

Código pronto não significa aplicativo funcionando. Depois de mexer em qualquer coisa que o
usuário vê, **abra o navegador e exercite o fluxo** antes de dizer que terminou.

## Quando usar

- Terminou uma feature ou correção de UI e quer confirmar o comportamento real
- Uma tela "não funciona" e você precisa ver o erro em vez de adivinhar
- Antes de abrir PR de mudança visual ou de fluxo (login, checkout, formulário)

**Não use quando:** a mudança é puramente de backend sem efeito visível (use os testes da API),
ou quando o projeto já tem E2E cobrindo exatamente esse fluxo — nesse caso rode a suíte.

## Escolha da ferramenta

| Situação | Use |
|---|---|
| Precisa da sessão real do usuário (já logado, extensões, cookies) | Claude in Chrome |
| Verificação repetível, headless, CI, app local | Playwright |
| Projeto já tem Playwright/Cypress configurado | a ferramenta do projeto |

Playwright é o padrão quando não há nada configurado — é reprodutível e não depende do navegador
do usuário.

## Ciclo de verificação

### 1. Suba o app e confirme que respondeu

Descubra o comando real (`package.json` → `scripts`, `README`, `Makefile`). Rode em background e
**espere a porta responder** antes de abrir o navegador:

```bash
npm run dev &
curl -sf --retry 20 --retry-delay 1 --retry-connrefused http://localhost:3000 > /dev/null && echo "up"
```

Nunca dependa de `sleep` fixo — ou o app ainda não subiu, ou você desperdiçou tempo.

### 2. Exercite o fluxo como um usuário

Não teste "a página carregou". Teste o caminho que importa:

- Navegue até a tela
- **Clique** nos botões do fluxo principal
- **Preencha** o formulário com dado válido → confirme sucesso
- **Preencha** com dado inválido → confirme a mensagem de erro
- Confirme o efeito colateral: redirect, item na lista, toast, registro no banco

Prefira seletores por papel/texto (`getByRole`, `getByLabel`) a CSS — eles quebram menos e
testam acessibilidade de brinde.

```javascript
await page.goto('http://localhost:3000/login');
await page.getByLabel('E-mail').fill('user@test.com');
await page.getByLabel('Senha').fill('senha-errada');
await page.getByRole('button', { name: /entrar/i }).click();
await expect(page.getByText(/credenciais inválidas/i)).toBeVisible();
```

### 3. Leia o console e a rede

Erro de console é falha, mesmo com a tela parecendo certa. Capture desde antes da navegação:

```javascript
const erros = [];
page.on('console', m => m.type() === 'error' && erros.push(m.text()));
page.on('pageerror', e => erros.push(String(e)));
page.on('response', r => r.status() >= 400 && erros.push(`${r.status()} ${r.url()}`));
```

No fim do fluxo, se `erros` não estiver vazio, **reporte** — não silencie por a tela ter
funcionado.

### 4. Registre screenshot

Uma por estado relevante (antes, depois, erro). Salve em pasta temporária, não no repo:

```javascript
await page.screenshot({ path: 'tmp/checkout-erro.png', fullPage: true });
```

Envie as imagens ao usuário quando o resultado for visual ou quando algo falhou.

### 5. Relate o que foi verificado

```markdown
**Verificado no navegador** (localhost:3000, Chromium)
- Login com credencial válida → redirect para /dashboard ✅
- Login com senha errada → mensagem "Credenciais inválidas" ✅
- Console: limpo
- Screenshot: tmp/login-erro.png

**Falhou:** botão "Salvar" no /perfil não responde — `TypeError: onSubmit is not a function`
em ProfileForm.tsx:42
```

Se falhou, diga que falhou com a evidência. Nunca relate sucesso sem ter executado.

## Armadilhas

- **`sleep` no lugar de espera por condição.** Use `waitForSelector` / `expect(...).toBeVisible()`;
  timing fixo gera teste que passa na sua máquina e falha na do outro.
- **Listener de console registrado depois do `goto`.** Você perde exatamente os erros de
  carregamento. Registre antes.
- **Testar só o caminho feliz.** O bug quase sempre está na validação e no estado de erro.
- **Deixar o servidor rodando.** Encerre o processo em background ao terminar.
- **Screenshot dentro do repositório.** Vai parar em um commit. Use `tmp/` ignorado.
- **Dado real em formulário.** Use dados fictícios; nunca credenciais de produção.
- **Concluir por "o código está certo".** Se você não abriu a página, você não verificou.

## Checklist

- [ ] App subiu e respondeu antes de abrir o navegador
- [ ] Caminho feliz **e** caminho de erro exercitados
- [ ] Console e respostas HTTP ≥400 monitorados desde o início
- [ ] Screenshot dos estados relevantes
- [ ] Relato com evidência, incluindo o que falhou
- [ ] Processos em background encerrados
