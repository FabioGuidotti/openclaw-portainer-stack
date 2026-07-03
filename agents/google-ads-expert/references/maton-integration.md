# Integração com o Maton (dados ao vivo + execução)

O **Maton** é a camada de execução do GoogleAdsExpert. No stack OpenClaw ele é
exposto pela skill `google-ads-api` (habilitada via `MATON_API_KEY`). É por ele
que o agente lê dados reais da conta e — quando suportado e confirmado — aplica
mudanças.

## Modelo mental

```
GoogleAdsExpert (raciocínio)  ──GAQL/ações──▶  Maton (google-ads-api)  ──▶  Google Ads API
        ▲                                                                        │
        └──────────────────── dados / resultado ─────────────────────────────────┘
```

- **Leitura (read):** o agente compõe uma query GAQL (ver `gaql-library.md`),
  pede ao Maton para executá-la e recebe o JSON de volta. GAQL cobre quase todo
  o superfície de leitura: campanhas, ad groups, keywords, budgets, conversões,
  Quality Score, change history.
- **Escrita (write):** pausar campanha, ajustar bid/budget, adicionar negativas,
  trocar estratégia de lance — **somente após confirmação explícita** (ver
  protocolo abaixo).

## Descoberta de capacidades (faça no início)

O agente **não deve presumir** quais ações o Maton expõe. No começo de uma sessão
de gestão:

1. Liste as ferramentas/ações disponíveis na skill `google-ads-api`.
2. Confirme quais são **read** (ex.: executar GAQL, listar contas acessíveis) e
   quais são **write** (ex.: mutate de campanha/budget/keyword).
3. Se **não houver ação de escrita**, opere em modo consultor puro: entregue o
   passo-a-passo manual para o humano executar (caminho de UI + valores exatos).

> Muitos servidores de Google Ads (MCP e afins) são **read-only via GAQL**. Trate
> escrita como um recurso que pode não existir e degrade graciosamente.

## Autenticação e conta

- Credencial via `MATON_API_KEY` (env do container). Nunca imprima a chave.
- Descubra a conta com o equivalente a `list_accessible_customers`; confirme o
  `customer_id` alvo com o usuário antes de auditar (importante em MCC).
- Para auditoria, prefira **escopo OAuth read-only**. Escrita exige escopo de mutação.

## Protocolo de leitura

1. Escolha a query em `gaql-library.md` conforme o check/categoria.
2. Respeite `gaql-notes.md` (campos incompatíveis, dedup, `ENABLED` only, janelas).
3. Execute via Maton; se falhar, registre o erro e marque os checks dependentes
   como **N/A** (diagnóstico G-SYS1) — nunca invente dados.

## Protocolo de escrita (WRITE COM CONFIRMAÇÃO)

Toda mutação segue este roteiro, sem exceção:

```
1. DIAGNÓSTICO  — o que está errado e por quê (evidência + check ID).
2. PROPOSTA     — recurso, valor atual → novo valor, e a chamada exata ao Maton.
3. IMPACTO/RISCO— impacto esperado (R$/CVR/CPA) e o risco de aplicar.
4. CONFIRMAÇÃO  — "Deseja que eu aplique? (confirmo / não)". AGUARDE resposta.
5. EXECUÇÃO     — só após "confirmo" explícito. Uma proposta = uma confirmação.
6. REGISTRO     — grave a mudança na memória (references/memory.md): data,
                  recurso, antes→depois, motivo, quem confirmou.
7. MEDIÇÃO      — defina quando/como reavaliar o efeito (princípio GROW).
```

Regras de segurança adicionais:

- **Respeite os Quality Gates** antes de propor: não sugira Broad sem Smart
  Bidding; não edite campanha em learning phase ativa; aplique o 3x Kill Rule.
- **Nunca** aplique um lote inteiro com uma só confirmação — confirme por bloco.
- **Mutações destrutivas** (pausar campanha ativa relevante, cortar budget de top
  performer) exigem destaque do risco e, de preferência, uma janela de medição.
- Se o resultado da API divergir do esperado, **pare e reporte** — não tente
  "consertar" com novas mutações não confirmadas.

## Exemplo (fluxo de escrita)

> **Diagnóstico:** a campanha `Search_NonBrand_SP` está com CPA R$182 vs target
> R$60 (3,03× → G-Kill). 3 tentativas de otimização nos últimos 30d sem melhora.
> **Proposta:** pausar a campanha (id 123456789). Chamada Maton: `campaign.mutate
> status=PAUSED`. **Impacto:** economiza ~R$3.400/mês; risco: perda de ~4 conv/mês
> de baixa qualidade. **Confirma a pausa? (confirmo / não)**

Só depois do "confirmo" o agente executa e registra na memória.
</content>
