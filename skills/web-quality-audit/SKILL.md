---
name: web-quality-audit
description: Use quando for auditar a qualidade de um site ou página web além da aparência — performance, Core Web Vitals, acessibilidade, SEO técnico e boas práticas. Roda Lighthouse e axe, mede LCP/INP/CLS, verifica meta tags, contraste, semântica e mobile, e devolve um relatório priorizado por impacto.
---

# Web Quality Audit

Bonito não significa bom. A mesma página pode estar lenta, inacessível, quebrada no celular e
invisível para o Google. Esta skill inspeciona o que não se enxerga olhando a tela.

## Quando usar

- Antes de colocar uma página nova em produção
- Quando alguém reclama de lentidão, ranking baixo ou uso no celular
- Auditoria periódica de landing page, e-commerce ou blog
- Depois de mudança grande de layout, fontes ou bibliotecas de terceiros

**Não use quando:** o objetivo é testar se o fluxo funciona (isso é `webapp-testing`) ou revisar
qualidade de código.

## Como rodar

Meça em **build de produção**, não em dev server — dev tem HMR, source maps e zero minificação,
os números não significam nada.

```bash
npm run build && npm run start        # ou o equivalente do projeto

npx lighthouse http://localhost:3000 \
  --preset=desktop \
  --output=json --output=html \
  --output-path=./tmp/lh-desktop \
  --chrome-flags="--headless"

npx lighthouse http://localhost:3000 \
  --output=json --output=html \
  --output-path=./tmp/lh-mobile \
  --chrome-flags="--headless"
```

Mobile é o padrão do Lighthouse e é o que o Google usa para ranquear — **sempre rode os dois** e
reporte mobile primeiro.

Acessibilidade com axe (pega coisas que o Lighthouse não pega):

```bash
npx @axe-core/cli http://localhost:3000 --exit
```

Lighthouse dá ~30% dos problemas de a11y automatizáveis. O resto exige teclado e leitor de tela.

## Core Web Vitals — metas

| Métrica | Bom | Precisa melhorar | Ruim | O que costuma causar |
|---|---|---|---|---|
| **LCP** (carregamento) | ≤ 2,5s | 2,5–4,0s | > 4,0s | imagem hero sem otimizar, fonte bloqueante, TTFB alto |
| **INP** (interatividade) | ≤ 200ms | 200–500ms | > 500ms | JS pesado na main thread, handler caro, re-render em cascata |
| **CLS** (estabilidade) | ≤ 0,1 | 0,1–0,25 | > 0,25 | imagem/iframe sem dimensão, fonte com swap, banner injetado |

Números de laboratório (Lighthouse) não são de campo. Se o site está no ar, confira o
**CrUX / Search Console** para dados reais de usuário — é o que conta para ranking.

## O que verificar em cada eixo

### Performance

- Imagens: formato moderno (AVIF/WebP), `width`/`height` explícitos, `loading="lazy"` fora da dobra, **nunca** lazy na imagem de LCP
- Fontes: `font-display: swap`, `preload` da fonte crítica, subset, self-host
- JS: bundle inicial, código de terceiros (analytics, chat, pixel — costuma dominar o INP), imports dinâmicos para o que está abaixo da dobra
- Rede: compressão (brotli), cache headers, HTTP/2+, sem redirect em cadeia
- Render: CSS crítico inline, nada bloqueando o `<head>` sem necessidade

### Acessibilidade

- **Teclado:** percorra a página inteira só com Tab. Todo interativo é alcançável, o foco é visível, a ordem faz sentido, não há armadilha de foco em modal
- **Contraste:** 4,5:1 para texto normal, 3:1 para texto grande e para ícone/borda com significado
- **Semântica:** um `<h1>`, hierarquia de headings sem pulo, landmarks (`nav`, `main`, `footer`), listas como listas
- **Formulários:** todo campo com `<label>` associado, erro descrito em texto (não só cor), `aria-describedby` ligando campo e mensagem
- **Imagens:** `alt` descritivo; `alt=""` em decorativa
- **Botão vs link:** ação é `<button>`, navegação é `<a href>`. `<div onClick>` é falha de acessibilidade

### SEO técnico

- `<title>` único (≤ ~60 chars) e `<meta name="description">` (≤ ~155 chars) por página
- Um `<h1>` alinhado ao título
- `<link rel="canonical">` correto — sem apontar todas as páginas para a home
- Open Graph e Twitter Card para preview de compartilhamento
- Dados estruturados (JSON-LD) do tipo certo: Article, Product, FAQ, Organization
- `robots.txt` e `sitemap.xml` acessíveis e coerentes; nenhum `noindex` acidental em produção
- URLs legíveis, sem parâmetro desnecessário; redirects 301 (não 302) em mudança definitiva
- Conteúdo renderizado sem JS ou com SSR — se o HTML vem vazio, o crawler pode não ver nada

### Mobile

- `<meta name="viewport" content="width=device-width, initial-scale=1">`
- Alvo de toque ≥ 44×44px com espaçamento
- Sem scroll horizontal (teste em 320px de largura)
- Texto legível sem zoom (≥ 16px em input, senão o iOS dá zoom sozinho)
- Hover não pode ser o único jeito de acessar algo

### Boas práticas

- HTTPS em tudo, sem conteúdo misto
- Sem erro no console
- CSP e headers de segurança básicos
- Bibliotecas sem vulnerabilidade conhecida (`npm audit`)

## Formato do relatório

Ordene por **impacto ÷ esforço**, não por seção. O usuário quer saber o que corrigir primeiro.

```markdown
# Auditoria — <url> (<data>)

| Eixo | Mobile | Desktop |
|---|---|---|
| Performance | 41 | 78 |
| Acessibilidade | 82 | 82 |
| SEO | 91 | 91 |
| Best Practices | 92 | 92 |

**Core Web Vitals (mobile):** LCP 5,1s ❌ · INP 180ms ✅ · CLS 0,28 ❌

## Corrigir primeiro

1. **Hero de 2,3 MB em PNG** — causa direta do LCP 5,1s.
   → Converter para AVIF + `priority`, remover `loading="lazy"`. Estimativa: LCP ~1,8s.
   `src/components/Hero.tsx:12`

2. **Carrossel sem `width`/`height`** — responsável por 0,21 do CLS 0,28.
   → Definir dimensões ou `aspect-ratio`. `src/components/Carousel.tsx:34`

## Depois

3. **12 botões com contraste 3,1:1** (mínimo 4,5:1) — `tailwind.config.js`, cor `brand-300`.

## Observações
- Não testado com leitor de tela; recomendo passada manual com NVDA.
```

Cada item: **o que está errado → por que importa → o que fazer → onde no código**. Achado sem
arquivo e linha é ruído.

## Armadilhas

- **Auditar o dev server.** Números inúteis. Sempre build de produção.
- **Reportar só o score.** "Performance 41" não é acionável; a causa raiz é.
- **Tratar Lighthouse como verdade sobre acessibilidade.** Ele automatiza uma fração; teste
  teclado manualmente e diga o que não foi coberto.
- **Ignorar terceiros.** Chat, pixel e tag manager frequentemente são a maior parte do problema —
  e a correção é política, não técnica. Reporte assim mesmo.
- **Uma única execução.** Lighthouse varia entre rodadas; rode 3 vezes e use a mediana antes de
  afirmar regressão.
- **Otimizar o que não é gargalo.** Confira a métrica antes e depois; sem medição, é palpite.

## Checklist

- [ ] Build de produção, mobile **e** desktop, mediana de 3 execuções
- [ ] Lighthouse + axe executados, HTML salvo em `tmp/`
- [ ] CWV comparados às metas, com a causa raiz identificada
- [ ] Navegação por teclado testada manualmente
- [ ] SEO: title, description, canonical, OG, sitemap, sem `noindex` acidental
- [ ] Testado em 320px sem scroll horizontal
- [ ] Relatório priorizado por impacto, cada item com arquivo e linha
