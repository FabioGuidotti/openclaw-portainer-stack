<!-- Origem metodológica: claude-ads (MIT) — google-audit.md (PMax G31-G35 / G-PM1..6, AI Max G-AI1, Demand Gen G-DG1..3) e ads-google/SKILL.md. -->

# Performance Max & o Stack de IA (Power Pack)

O **Power Pack** é a recomendação do Google para máxima cobertura de inventário: **PMax + Demand Gen + AI Max for Search** rodando como um stack unificado. É a era pós-keyword — o algoritmo controla placement, bid e combinação de criativo, e o trabalho do consultor migra de "ajustar match type" para "alimentar o algoritmo com asset density, audience signals e negativas certas". Como consultor contínuo, o agente lê o estado do stack ao vivo (via Maton/GAQL) e recomenda; executa só após confirmação humana.

## Pré-requisito inegociável: volume de conversão

PMax precisa de **30-50+ conversões/mês** para otimizar de forma confiável. Abaixo disso, o algoritmo não tem sinal suficiente e o resultado é errático — nenhuma quantidade de asset compensa dado escasso. Este é o portão THINK (principles.md): antes de recomendar ou defender PMax, cheque o volume. Contas com <30 conv/mês devem ficar em Search com Smart Bidding até acumularem sinal. AI Max exige >50 conv/mês além de listas de negativas estabelecidas (G-AI1).

---

## Checks de PMax — assets e estrutura

### G31 — Densidade de assets (Critical)
- **Pass:** ≥20 imagens, ≥5 logos, ≥5 vídeos nativos por asset group (densidade máxima) E ≥30 conv/mês.
- **Warning:** 5-19 imagens, 1-4 logos ou 1-4 vídeos; OU <30 conv/mês (dado insuficiente para PMax).
- **Fail:** <5 imagens OU 0 logos OU 0 vídeo.
- Flag vídeo auto-gerado a partir de imagens como **Warning** — qualidade tipicamente ruim; suba vídeo nativo. Densidade é a alavanca #1 de PMax (ver creatives.md).

### G32 — Vídeo nativo (High)
- **Pass:** vídeo nativo em todos os formatos (16:9, 1:1, 9:16). **Warning:** 1-2 formatos. **Fail:** sem vídeo nativo (só auto-gerado).
- Sem vídeo nativo, o PMax gera um slideshow pobre a partir das imagens e serve em YouTube com qualidade baixa.

### G33 — Asset groups (Medium)
- **Pass:** ≥2 asset groups por PMax, segmentados por intenção. **Warning:** 1 asset group.
- Múltiplos asset groups permitem sinais e criativos distintos por segmento de intenção/produto.

### G34 — URL expansion (High)
- **Pass:** configurado intencionalmente (ON para descoberta, OFF para controle). **Fail:** default ON sem revisão.
- URL expansion ON manda tráfego para a melhor página, não só a Final URL — ótimo para descoberta, perigoso se houver páginas de checkout-skip, gated ou 404. Decida com intenção.

---

## Checks de PMax estendido (G-PM)

### G-PM1 — Audience signals (High)
- **Pass:** audience signals custom por asset group. **Warning:** sinais genéricos. **Fail:** nenhum.
- **Customer Match é o sinal mais forte** para PMax (ver audiences.md, G57). Audience signal em PMax não restringe — acelera o aprendizado indicando por onde começar.

### G-PM2 — Ad Strength (High)
- **Pass:** "Good" ou "Excellent". **Warning:** "Average". **Fail:** "Poor". Mesma lógica do G29 (creatives.md).

### G-PM3 — Brand cannibalization (High)
- **Pass:** <15% das conversões de PMax vêm de termos de marca. **Warning:** 15-30%. **Fail:** >30%.
- Sem brand exclusion, o PMax "rouba" conversões de marca que aconteceriam de graça e infla o ROAS aparente. Configure brand exclusions quando houver campanha de Search de marca (relaciona a G07).
- **Detecção de marca:** não confie só no nome da campanha. Derive tokens de marca do nome do negócio e escaneie o texto real dos search terms; >50% de termos de marca = conversão de marca.

### G-PM4 — Search themes (Medium)
- **Pass:** search themes configurados (até 50 por asset group). **Warning:** <5. **Fail:** nenhum.
- Search themes dizem ao PMax quais consultas priorizar — sinal direto de intenção, a coisa mais próxima de keyword no PMax.

### G-PM5 / G-PM6 — Negativas em PMax (High)
Historicamente PMax não aceitava negativas; **agora negative keywords em nível de campanha estão disponíveis para TODOS os anunciantes (2025)**.
- **G-PM5 — Pass:** negativas de marca + irrelevantes aplicadas (até 10.000). **Warning:** algumas. **Fail:** nenhuma.
- **G-PM6 (Quick Win 10 min) — Pass:** negativas em nível de campanha configuradas. **Warning:** só nível de conta. **Fail:** nenhuma apesar da disponibilidade.
- Um cliente reportou 15% de redução imediata de custo após adicionar negativas. Este é hoje um dos quick wins de maior impacto em PMax.

---

## AI Max for Search (G-AI1, High)

AI Max sobrepõe tecnologia de broad match + targeting keywordless + criativo gerado por IA às campanhas de Search existentes. Média de **+14% de conversões a CPA/ROAS similar** (não-varejo). Calibre expectativa: dados independentes de 250+ campanhas mostram +13% receita mediana e +16% CPA — mais conservador que o número oficial.

- **Pass:** AI Max avaliado ou ativo em contas com dado de conversão suficiente E listas de negativas fortes já em pé.
- **Fail:** não avaliado apesar de conta elegível (>50 conv/mês, listas de negativas estabelecidas).
- **Pré-requisito duro:** listas de negativas fortes antes de habilitar — AI Max amplia o alcance 3-5x e sem negativas escaladas sangra budget.
- Detecção: `campaign.ai_max_setting.enable_ai_max` (Google Ads API v21+).
- **Migração DSA→AI Max:** DSA, ACA e broad match em nível de campanha auto-migram para AI Max até fim de setembro/2026. Manual CPC/ECPC precisam ir para Smart Bidding antes. Capture baseline de 28 dias pré-migração (CTR/CVR/CPA/ROAS/Search Lost IS) para medir impacto limpo (GROW, principles.md).

---

## Demand Gen (G-DG1..3)

Demand Gen substituiu as Video Action Campaigns (VAC). **Migração/auto-upgrade de VAC concluída em abril/2026** — qualquer VAC restante está deprecada.

### G-DG1 — Assets de imagem (High)
- **Pass:** Demand Gen com vídeo **E** imagem. **Warning:** só vídeo (perde o uplift). **Fail:** sem Demand Gen apesar de conta elegível.
- Vídeo + imagem = +20% de conversões ao mesmo CPA vs só-vídeo. Caso DoorDash: 15x mais CVR, 50% menos CPA.

### G-DG2 — Status de migração de VAC (Critical)
- **Pass:** todas as VAC migradas para Demand Gen (auto-upgrade abr/2026). **Warning:** migração em curso. **Fail:** VAC ainda ativa (deprecada, será migrada à força).

### G-DG3 — Perda de frequency capping (High)
Demand Gen **não suporta frequency capping** — perda significativa vinda da VAC.
- **Pass:** ex-VAC com caps agora têm estratégia alternativa de medição (Video Frequency Groups em alpha, ou monitoramento manual de frequência). **Warning:** frequência não monitorada pós-migração. **Fail:** ex-VAC dependia de caps agora perdidos, sem estratégia de reposição.

---

## O stack como sistema (CONNECT-System)

PMax, Demand Gen e AI Max compartilham budget, audience signals e listas de negativas. Recomendações têm de ser coerentes entre eles (principles.md):
- Habilitar AI Max sem escalar negativas 3x quebra o sistema — alcance sobe 3-5x sem controle.
- Brand exclusion em PMax (G-PM3/G07) e em AI Max usam o mesmo mecanismo; aplique nos dois quando houver Search de marca.
- Customer Match fresca (audiences.md, G57) é o sinal transversal que fortalece os três ao mesmo tempo.
- Densidade e diversidade de criativo (creatives.md) são a alavanca comum: em PMax e Demand Gen, o criativo é o targeting.

## GAQL úteis

Estado de AI Max e sub-tipo de campanha:
```sql
SELECT campaign.name, campaign.advertising_channel_type,
       campaign.advertising_channel_sub_type
FROM campaign
WHERE campaign.status = 'ENABLED'
```

Conversões de PMax por origem (para G-PM3, brand cannibalization):
```sql
SELECT campaign.name, metrics.conversions, metrics.conversions_value
FROM campaign
WHERE campaign.advertising_channel_type = 'PERFORMANCE_MAX'
  AND segments.date DURING LAST_30_DAYS
```

## Ordem de recomendação típica

1. Cheque o portão: ≥30-50 conv/mês? Se não, adie PMax/AI Max.
2. **G-PM6** negativas em PMax (quick win, ~15% de economia).
3. **G-PM3/G07** brand exclusion se houver Search de marca.
4. **G31/G32** densidade e vídeo nativo — a maior alavanca de performance.
5. **G-PM1** audience signals (Customer Match primeiro).
6. **G-PM4** search themes; **G33** asset groups por intenção; **G34** URL expansion revisado.
7. **G-DG2** migrar VAC restante; **G-DG1** adicionar imagem ao Demand Gen; **G-DG3** repor medição de frequência.
8. **G-AI1** avaliar AI Max — só depois de negativas fortes e baseline capturado.
