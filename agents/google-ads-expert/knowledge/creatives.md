<!-- Origem metodológica: claude-ads (MIT) — google-audit.md (Ads & Assets G26-G35, G-AD1), google-creative-specs.md, copy-frameworks.md. -->

# RSA, Assets & Copy — O Criativo como Alavanca

Na era Andromeda/Power Pack, o criativo deixou de ser enfeite e virou a principal alavanca de performance: em PMax e Demand Gen, onde não há keyword para controlar, **o criativo É o targeting**. Quanto mais diverso e forte o pool de assets, mais o algoritmo tem para combinar com cada usuário e placement. Este arquivo cobre os checks de RSA (G26-G30), ad freshness (G-AD1), specs criativos do Google e os seis frameworks de copy. Como consultor contínuo, o agente lê Ad Strength e composição de assets ao vivo e recomenda; executa só após confirmação humana.

## Checks de RSA e Assets

### G26 — RSA por ad group (High)
- **Pass:** ≥1 RSA por ad group (≥2 recomendado). **Warning:** exatamente 1. **Fail:** ad groups sem nenhum RSA.
- Dois RSAs por ad group dão ao algoritmo variação para testar sem depender só de rotação interna de assets.

### G27 — Headlines (High)
- **Pass:** ≥8 headlines únicas por RSA (ideal 12-15). **Warning:** 3-7. **Fail:** <3.
- Limite: 3 a 15 headlines, 30 caracteres cada. Mais headlines = mais combinações = melhor Ad Strength.

### G28 — Descriptions (Medium)
- **Pass:** ≥3 descriptions por RSA (ideal 4). **Warning:** 2. **Fail:** <2.
- Limite: 2 a 4 descriptions, 90 caracteres cada.

### G29 — Ad Strength (High)
- **Pass:** todos os RSAs "Good" ou "Excellent". **Warning:** alguns "Average". **Fail:** qualquer RSA "Poor".
- Ad Strength mede diversidade e relevância dos assets. Mas cuidado (FEEL, principles.md): um RSA "Excellent" emocionalmente morto ainda falha. Compliance de spec não substitui ressonância.

### G30 — Pinning (Medium)
- **Pass:** pinning estratégico (1-2 posições, 2-3 variantes cada). **Warning:** over-pinned (todas as posições). 
- Pinning demais mata a flexibilidade do RSA e derruba o Ad Strength. Pine só o que precisa ser fixo por lei ou marca (disclaimer, nome da marca em posição específica), deixando 2-3 variantes por posição pinada.

### G35 / G-KW2 — Relevância copy↔keyword (High)
- Headlines devem conter variantes da primary keyword do ad group. **Fail:** nenhuma relevância nas headlines. Isso alimenta Quality Score (ad relevance) e Ad Strength ao mesmo tempo.

### G-AD1 — Ad freshness (Medium)
- **Pass:** nova copy testada nos últimos 90 dias. **Fail:** nenhum anúncio novo em >90 dias.
- Criativo fadiga. Sem refresh, o CTR decai e o algoritmo fica sem material novo para testar. Amarra com GROW (principles.md): o loop de teste de copy é contínuo.

---

## Specs criativos do Google

### Performance Max — asset group (imagens)
| Tipo | Dimensões | Ratio | Prioridade |
|---|---|---|---|
| Marketing (landscape) | 1200×628 | 1.91:1 | Required |
| Square | 1200×1200 | 1:1 | Required |
| Portrait | 960×1200 | 4:5 | High |
| Logo landscape | 1200×300 | 4:1 | Required |
| Logo square | 1200×1200 | 1:1 | Required |

Máximo 20 imagens por asset group (marketing + square + portrait). JPG/PNG, máx 5MB, mín 128×128. Set mínimo viável: 1200×628, 1200×1200, 960×1200. Cobertura plena: adicione 1080×1920 vertical para YouTube Shorts. Ver densidade em pmax.md (G31: ≥20 imagens, ≥5 logos, ≥5 vídeos nativos).

### Demand Gen (ex-Discovery)
| Placement | Ratio | Tamanho |
|---|---|---|
| Google Discover | 1:1 | 1080×1080 |
| Google Discover | 4:5 | 1080×1350 |
| Gmail Promotions | 1.91:1 | 1200×628 |
| YouTube In-Feed | 1:1 | 1080×1080 |

Gere 1:1 e 4:5 para cobertura máxima de placement.

### YouTube thumbnails
- Standard 1280×720 (16:9) para in-feed/search; square 1080×1080 (1:1) para Shorts.
- Alto contraste sujeito/fundo; rosto ou produto no centro-esquerda (overlay de texto vai à direita); fundo limpo; cores vibrantes superam paletas apagadas em CTR.

### RSA — limites de copy
| Componente | Mín | Máx | Limite |
|---|---|---|---|
| Headlines | 3 | 15 | 30 chars |
| Descriptions | 2 | 4 | 90 chars |
| Display paths | — | 2 | 15 chars |

Best practice: 8+ headlines, 2+ descriptions.

### Modificadores de prompt de imagem (Google)
Sempre inclua: "horizontal composition" (1.91:1 e 16:9), "clean background", "subject centered with breathing room", "no text overlay" (texto é aplicado pela plataforma), "high contrast, vibrant colors". Evite: close-ups extremos (PMax corta em vários placements), layouts complexos (cortam mal em 1:1 e 4:5), texto/logo embutido na imagem. Para AI Max, forneça pool diverso (3+ aspect ratios, 3+ ângulos visuais) — quanto mais material, mais a IA tem para selecionar.

---

## Seis frameworks de copy

Escolha por temperatura da audiência e objetivo. Teste dois frameworks em A/B antes de escalar spend.

| Framework | Expansão | Melhor para |
|---|---|---|
| AIDA | Attention, Interest, Desire, Action | Audiências frias, awareness, lançamento |
| PAS | Problem, Agitate, Solution | Produtos de dor, retargeting |
| BAB | Before, After, Bridge | Ofertas de transformação |
| 4P | Promise, Picture, Proof, Push | High-ticket, B2B enterprise |
| FAB | Features, Advantages, Benefits | Produtos técnicos, alta intenção |
| Star-Story-Solution | Star, Story, Solution | Brand storytelling, UGC |

**AIDA** — gancho de interrupção + detalhe + benefício desejado + CTA único. RSA headline (30): `[gancho] [benefício]`; description (90): `[detalhe]. [benefício desejado]. [CTA com urgência].` Não empilhe CTAs; não enterre o gancho.

**PAS** — problema + agitação específica + solução como alívio natural. RSA headline: `[keyword do problema] resolvido`; description: `[problema]. [agitação]. [solução]. [CTA com benefício].` Não superdramatize (gera reprovação de anúncio).

**BAB** — estado antes + estado depois + ponte (produto como o meio). RSA headline: `De [antes] a [depois]`; description: `[dor antes]. [benefício depois]. [ponte: produto]. [CTA].` Contraste vívido, ponte concisa, sem claims irreais.

**4P** — promessa ousada + imagem do resultado + prova (número) + empurrão. RSA headline: `[promessa] [prova]`; description: `[promessa]. [imagem do resultado]. [prova social]. [push CTA].` Prova verificável; nada de "muitos clientes adoram".

**FAB** — feature + vantagem sobre alternativas + benefício tangível. RSA headline: `[feature] [vantagem-chave]`; description: `[feature]. [vantagem vs concorrente]. [benefício]. [CTA].` Traduza toda feature em benefício; evite jargão que a audiência não entende.

**Star-Story-Solution** — herói relatable + arco narrativo (um desafio, uma resolução) + revelação do produto. RSA headline: `[star] confia em [marca]`; description: `[star]. [arco]. [revelação da solução]. [CTA].` O star não pode parecer ator pago; a história não pode ofuscar o produto.

**Seleção rápida:** frias → AIDA ou Star-Story-Solution (awareness), BAB/PAS (consideração); mornas → PAS/4P (consideração), FAB/BAB (conversão), PAS com urgência (retargeting); quentes → FAB/4P (upsell), Star-Story-Solution (retenção). Na dúvida: PAS para audiência ciente da dor, AIDA para alcance amplo.

---

## Criativo como alavanca em PMax / Demand Gen

O elo com o Power Pack (pmax.md): em PMax e Demand Gen o algoritmo monta o anúncio combinando assets do pool com cada usuário. Poucos assets = poucas combinações = performance limitada, independentemente do budget. Por isso:
- **Densidade** (G31) e **vídeo nativo** (G32) são as alavancas de PMax mais diretas — mais que ajuste de bid.
- **Diversidade de ângulo** importa tanto quanto quantidade: aplique frameworks diferentes (PAS, BAB, FAB) ao mesmo produto para dar variação semântica ao pool.
- **Ad freshness** (G-AD1) mantém o pool vivo; sem refresh, a fadiga corrói o CTR e o algoritmo estagna.
- Em Demand Gen, combine vídeo + imagem: +20% de conversões ao mesmo CPA vs só-vídeo (ver pmax.md, G-DG1).
