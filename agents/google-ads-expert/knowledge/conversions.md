<!-- Origem metodológica: claude-ads (MIT) — conversion-tracking.md e google-audit.md (Conversões G42-G49, G-CT, G-CTV). -->

# Conversion Tracking — A Fundação (peso 25%)

Conversion tracking é a categoria de maior peso no Google Ads Health Score (25%) porque é a fundação sobre a qual todo o resto se apoia. Smart Bidding, DDA, Enhanced Conversions e o Power Pack inteiro só funcionam se o sinal de conversão for verdadeiro, completo e não duplicado. **Se o tracking está quebrado, toda otimização acima dele é otimização em cima de ruído** — o algoritmo aprende com dados errados, o ROAS reportado é ficção e cada recomendação de budget/bid herda o erro. Como consultor contínuo, o agente lê o estado do tracking ao vivo antes de recomendar qualquer coisa em bidding ou estrutura. Recomenda; executa só após confirmação humana.

## Por que tracking quebrado invalida tudo

| Sintoma | Causa provável | Consequência a jusante |
|---|---|---|
| Smart Bidding não sai da learning phase | Volume de conversão insuficiente ou tag intermitente (G-CT3) | Bids errados, spend desperdiçado |
| ROAS reportado ≠ receita real | Double-counting GA4 + native (G-CT1) | Budget mal alocado para campanhas "vencedoras" fantasma |
| Conversões despencaram na UE | Consent Mode V2 ausente ou Basic (G45) | 90-95% de queda de métrica; DDA sem dado |
| CPA sobe sem explicação | Micro-conversões como Primary (G47) | Algoritmo otimiza para AddToCart, não para receita |

Regra operacional: **nunca recomende mudança de bidding, budget ou estrutura antes de validar tracking.** Um audit que pontua estrutura antes de confirmar G42/G43/G45/G-CT1 está construindo sobre areia.

---

## Checks da fundação

### G43 — Enhanced Conversions (Critical, Quick Win 5 min)
Envia dados first-party com hash SHA-256 (email, telefone, endereço, nome). Recupera ~10% de conversões medidas e é gratuito. Requisito para acurácia de Smart Bidding em ambiente cookie-degraded.
- **Pass:** ativo E verificado para as conversões primárias.
- **Warning:** ativo mas não verificado — cheque o status de verificação em settings.
- **Fail:** não habilitado.
- Configuração via gtag.js ou GTM. Convive com o tracking padrão.

### G44 — Server-side tracking (High)
Server-side GTM (sGTM) ou import de conversão via Google Ads API. Durabilidade de dado contra ad blockers e ITP. Recuperação de acurácia de 10-30%.
- **Pass:** sGTM ou API import ativo. **Warning:** planejado, não deployado. **Fail:** nenhum.
- Para e-commerce, lead gen e SaaS, server-side é Critical na prática.

### G45 — Consent Mode V2 (Critical)
Obrigatório para EEA/UK; enforcement começou 21/jul/2025. **Advanced mode é mandatório** — Basic causa perda enorme de dado.
- Ativa modelagem de conversão para usuários sem consentimento. Requer **700+ cliques/dia por 7 dias por país/domínio** para a modelagem comportamental ativar.
- Combinado com Enhanced Conversions + server-side, recupera 30-50% das conversões perdidas.
- Sem implementação: quedas de 90-95% de métrica. ~31% dos usuários aceitam cookies globalmente.
- **Pass:** Advanced implementado. **Warning:** só Basic (upgrade imediato). **Fail:** não implementado.

```javascript
// Default (antes do consentimento)
gtag('consent', 'default', {
  'ad_storage': 'denied', 'ad_user_data': 'denied',
  'ad_personalization': 'denied', 'analytics_storage': 'denied'
});
// Após consentimento
gtag('consent', 'update', {
  'ad_storage': 'granted', 'ad_user_data': 'granted',
  'ad_personalization': 'granted', 'analytics_storage': 'granted'
});
```

### G46 — Janela de conversão (Medium)
A janela precisa bater com o ciclo de venda, senão a atribuição corta conversões válidas (ciclo longo) ou infla ruído (ciclo curto).
- **Pass:** 7d para e-commerce, 30-90d para B2B, 30d para lead gen.
- **Warning:** default 30d sem validação. **Fail:** janela descasada do ciclo.
- Janelas disponíveis: clique 1/3/7/30(default)/60/90 dias; engaged-view 3d; view-through 1d.

### G47 — Micro vs macro (High)
Só conversões macro (Purchase, Lead) devem ser **Primary** para bidding. Micro-eventos (AddToCart, TimeOnSite) como Primary fazem o algoritmo otimizar para o sinal errado.
- **Pass:** só macro como Primary. **Warning:** alguns micro como Primary. **Fail:** todos os eventos, incluindo micro, como Primary.
- Micro-conversões ficam como Secondary (observação), nunca como alvo de bidding.

### G48 — Atribuição DDA (Medium)
Data-Driven Attribution é o **default mandatório desde setembro/2025**. Restam apenas dois modelos: DDA e Last Click. Todos os rule-based (first-click, linear, time decay, position-based) foram descontinuados e auto-migrados para DDA. Sem threshold mínimo de dado para DDA.
- **Pass:** DDA selecionado. **Warning:** Last Click intencional (documente o motivo). **Fail:** modelo rule-based ativo — é misconfiguration legada.
- **Nota de acurácia (G48/CT-FL5):** exclua conversões system-managed de Smart Campaign (ex.: 'Smart campaign map clicks to call'); modelo e counting type são travados pelo Google. Avalie só ações controladas pelo anunciante.

### G49 — Value assignment (High)
- **Pass:** valores dinâmicos para e-commerce; value rules para lead gen. **Warning:** valores estáticos. **Fail:** sem valores.
- Sem valor de conversão, tROAS é impossível e o algoritmo trata todas as conversões como iguais.

---

## Integridade do sinal (G-CT)

### G-CT1 — Sem double-counting (Critical)
GA4 e Google Ads não podem contar a mesma conversão. Use o tracking nativo do Google Ads como **PRIMARY para bidding** (dado em tempo real) e importe conversões do GA4 apenas para observação. Nunca conte as duas.
- **Nota de acurácia:** cheque duplicidade **apenas em ações ENABLED**. Exclua HIDDEN e REMOVED — já estão desativadas e não causam double-counting. Ao reportar duplicata, inclua ID da ação, tipo, origem, categoria, status, flag primary/secondary, counting type e modelo de atribuição para resolução fácil.

### G-CT2 — GA4 linkado e fluindo (High)
- **Pass:** propriedade GA4 linkada, dado fluindo. **Warning:** linkado mas com discrepância. **Fail:** não linkado.

### G-CT3 — Tag firing (Critical)
gtag.js ou GTM disparando corretamente em todas as páginas.
- **Pass:** firing correto em todas. **Warning:** firing em >90% das páginas. **Fail:** tag ausente ou quebrada em páginas-chave.
- Tag intermitente é insidiosa: passa despercebida e envenena o Smart Bidding aos poucos. Verifique com GAQL/tag assistant ao vivo.

### G-CTV1 — CTV / Floodlight (High)
**Floodlight NÃO mede conversão em dispositivos CTV.** Campanhas de CTV precisam de medição não-Floodlight.
- **Pass:** CTV usa conversion tracking do Google Ads ou GA4. **Warning:** CTV ativo mas medição não verificada. **Fail:** CTV dependendo de Floodlight (não captura conversões de CTV).

---

## GAQL úteis

Ações de conversão e seus atributos (para G42/G47/G48/G-CT1):
```sql
SELECT conversion_action.name, conversion_action.type,
       conversion_action.category, conversion_action.status,
       conversion_action.primary_for_goal,
       conversion_action.counting_type,
       conversion_action.attribution_model_settings.attribution_model
FROM conversion_action
WHERE conversion_action.status = 'ENABLED'
```

Lag de conversão (ainda pingando? valida janela G46):
```sql
SELECT segments.conversion_lag_bucket, metrics.conversions
FROM campaign
WHERE segments.date DURING LAST_30_DAYS
```

---

## Ordem de checagem recomendada

1. **G-CT3** tag firing — se a tag não dispara, todo o resto é inválido.
2. **G42** existe conversão primária.
3. **G-CT1** sem double-counting — corrija antes de olhar qualquer ROAS.
4. **G43** Enhanced Conversions (quick win imediato).
5. **G45** Consent Mode V2 (se serve EEA/UK).
6. **G47** micro vs macro; **G48** DDA; **G46** janela; **G49** valor.
7. **G44** server-side; **G-CT2** GA4; **G-CTV1** CTV.

Só depois de os itens Critical (G42, G43, G45, G-CT1, G-CT3) estarem verdes é que recomendações de bidding e budget carregam confiança. Isso é o princípio CONNECT-System (principles.md) aplicado ao tracking: o stack de sinal é um sistema, e uma recomendação num nó tem de ser coerente com os demais.
