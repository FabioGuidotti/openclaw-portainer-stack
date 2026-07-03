<!-- Origem metodológica: claude-ads (MIT) — ads-google/SKILL.md (Output/Health Score) e google-audit.md (severidade, Quick Wins). -->

# Princípios de Relatório & Comunicação com Stakeholder

Um audit de Google Ads só gera valor quando vira decisão. Este arquivo define os **princípios** de como o GoogleAdsExpert estrutura o output, prioriza por severidade e escreve recomendações acionáveis — os templates concretos vivem em `reports/`. O agente é um consultor contínuo: lê a conta ao vivo, entrega findings e recomenda; executa mudança só após confirmação humana. Por isso toda recomendação precisa ser boa o bastante para o humano dizer "sim, execute" sem ter de reconstruir o raciocínio. Isto materializa o princípio CREATE (principles.md): pare de analisar e entregue algo que fecha em decisão.

## Estrutura do output

Todo relatório segue a mesma espinha, do mais decisório ao mais detalhado — o stakeholder lê de cima para baixo e para quando já tem o que precisa.

1. **Health Score** — nota 0-100 com grade, quebrada por categoria e peso. Dá o veredito em cinco segundos.
2. **Top findings** — os 3-5 achados que mais movem o ponteiro, cada um com impacto e severidade. Não é a lista completa; é a lista que importa.
3. **Quick wins** — correções de severidade Critical/High que levam <15 min. Momentum imediato, confiança ganha cedo.
4. **Plano de ação priorizado** — todos os findings acionáveis, ordenados por severidade->prazo, cada um no formato de recomendação abaixo.
5. **Anexo técnico** — os checks completos (pass/warning/fail), matrizes de keyword, GAQL de suporte. Para quem quer auditar o raciocínio.

### Health Score

```
Google Ads Health Score: XX/100 (Grade: X)

Conversion Tracking: XX/100  ########..  (25%)
Wasted Spend:        XX/100  ##########  (20%)
Account Structure:   XX/100  #######...  (15%)
Keywords:            XX/100  #####.....  (15%)
Ads:                 XX/100  ########..  (15%)
Settings:            XX/100  ##########  (10%)
```

O Health Score é a síntese (CONNECT-System, principles.md): as categorias não são relatórios paralelos, colapsam num número ponderado. Sempre mostre os pesos — o stakeholder precisa entender que Conversion Tracking a 40/100 dói mais que Settings a 40/100.

## Severidade -> prazo

A severidade de cada check traduz-se diretamente em prazo de ação. Isto tira a priorização do "achismo" e a ancora na régua do audit.

| Severidade | Prazo | Significado | Exemplos |
|---|---|---|---|
| **Critical** | Imediato | Invalida dado ou sangra budget agora | G45 Consent Mode ausente, G-CT1 double-counting, G42 sem conversão, ECPC ativo |
| **High** | 7 dias | Perda material de performance | G43 Enhanced Conversions, G-PM6 negativas PMax, G31 densidade de assets |
| **Medium** | 30 dias | Ineficiência corrigível sem urgência | G46 janela de conversão, G33 asset groups, G-AD1 ad freshness |
| **Low** | Backlog | Melhoria marginal, faça quando sobrar | G10 ad schedule, G55 lead form extensions |

Regra de ouro: **um Critical não verde bloqueia recomendações que dependem dele.** Não recomende otimização de bidding (Medium/High) enquanto o tracking (Critical) estiver quebrado — seria construir sobre areia (ver conversions.md). Sequencie por dependência, não só por severidade.

## Como escrever uma recomendação

Toda recomendação no plano de ação carrega quatro elementos. Sem os quatro, é observação, não recomendação.

**Impacto estimado + Ação + Owner + ETA**

- **Impacto estimado** — o "por que agora", em número quando possível. "~R$3.200/mês em spend desperdiçado" bate infinitamente "melhora a eficiência". Puxe do dado real (wasted spend, uplift esperado do check).
- **Ação** — o passo concreto, específico o bastante para executar sem reinterpretar. Inclua o check ID de referência (G45, G-PM6) e GAQL/passo de UI quando útil.
- **Owner** — quem faz. Como consultor contínuo, distinga o que o agente executa após confirmação (mudança na conta via Maton) do que precisa do time do cliente (dev instala tag, marketing sobe criativo).
- **ETA** — prazo derivado da severidade (imediato/7d/30d/backlog).

Exemplo:
> **[Critical · imediato]** Consent Mode V2 ausente (G45). **Impacto:** recuperação de 15-25% das conversões modeladas na UE; sem ele o DDA e o Smart Bidding operam com dado 90-95% incompleto no tráfego EEA. **Ação:** implementar Advanced Consent Mode V2 via GTM, com sinais `ad_storage`/`ad_user_data`/`ad_personalization`. **Owner:** dev do cliente (implementação) + agente (verificação pós-deploy). **ETA:** esta semana.

Recomendações fracas (anti-pattern, principles.md ACCEPT/CREATE): "otimizar Quality Score", "revisar campanhas", "considerar Smart Bidding". Não têm número, não têm passo, não têm dono — forçam o próximo a decidir tudo.

## Relatório executivo vs técnico

O mesmo audit produz duas leituras. Não confunda os públicos.

| Dimensão | Executivo | Técnico |
|---|---|---|
| Público | Cliente/decisor, dono do budget | Gestor de tráfego, quem executa |
| Foco | Impacto em R$, risco, ROI das correções | Check IDs, GAQL, thresholds, passos de UI |
| Profundidade | Health Score + top findings + quick wins | 80 checks completos, matrizes, notas de acurácia |
| Linguagem | Negócio ("perda de receita", "recuperação") | Técnica (Quality Score, DDA, Ad Strength, learning phase) |
| Tamanho | 1 página, escaneável | Completo, referenciável |
| Pergunta que responde | "Vale a pena e quanto custa não fazer?" | "Exatamente o que mudar e como?" |

O executivo lidera com dinheiro e decisão; o técnico lidera com precisão e reprodutibilidade. Ambos derivam do mesmo Health Score e do mesmo conjunto de findings — mudam a lente, não os fatos (LISTEN, principles.md: fale a língua de quem lê).

## Princípio de fechamento — o loop (GROW)

Todo relatório planta o próximo ciclo:
- Cada recomendação carrega critério de medição — se não dá para medir se funcionou, não vira aprendizado.
- Capture o baseline (28d de CTR/CVR/CPA/ROAS) no relatório para comparar na re-auditoria de 30/90 dias.
- Como consultor contínuo, o agente reabre findings quando a métrica regride ao vivo — o relatório é um marco no loop, não um evento único.

Um bom relatório não é o que lista mais problemas; é o que provoca a maior quantidade de boas decisões no menor tempo.
