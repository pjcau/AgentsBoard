# AgentsBoard — Ricerca di Mercato

**Data**: Marzo 2026
**Versione**: 2.0

---

## 1. Executive Summary

Il mercato degli strumenti per sviluppatori AI sta esplodendo. Nel 2025-2026, il paradigma è passato da "un assistente AI" a "una flotta di agenti AI" che lavorano in parallelo. GitHub ha lanciato Agent HQ, JetBrains ha Air, Warp è diventato 2.0 agentico, Spotify ha costruito Honk internamente.

Tuttavia, **nessun tool oggi combina fleet management, code review in-the-loop, cost aggregation cross-provider, e performance nativa GPU in un'unica app**. Ogni competitor copre un pezzo del puzzle:

- **GitHub Agent HQ**: Fleet management ma locked nell'ecosistema GitHub
- **Warp 2.0**: Agent management ma terminal-only, no code review
- **JetBrains Air**: Multi-agent ma preview, tied to JetBrains
- **Composio**: Open-source orchestrator ma alpha, no GUI polish
- **AgentHub**: Diff review + IDE-lite ma no fleet, no GPU rendering
- **Cosmodrome**: GPU + fleet + MCP ma no diff review, no editor

AgentsBoard unisce tutto questo in un prodotto che non esiste.

---

## 2. Panorama Competitivo

### 2.1 IDE AI-Native (Editor-first)

| Tool | Pricing | Punti di forza | Limiti |
|------|---------|----------------|--------|
| **Cursor** | $20/mo Pro (credit-based) | 1M+ utenti, 360K paganti. AI integrato, Tab completion, multi-file edit | Single-agent, no fleet, Electron, credit system costoso per heavy users |
| **Windsurf (Codeium → Cognition)** | $15/mo ind, $30 team | Cascade flow, $82M ARR. Acquisita da Cognition AI (Devin) luglio 2025 | Futuro incerto sotto Cognition, single-agent, Electron |
| **Zed** | Free (open-source) | Rust/GPU nativo, performance-first | Single-agent, AI features early-stage |
| **Augment Code** | $20-250/mo (tier) | Deep codebase understanding, context-aware | Credit-based, power users $200+/mo |

**Gap**: Tutti single-agent. Nessuno gestisce flotte.

### 2.2 CLI AI Agents (Terminal-first)

| Tool | Pricing | Punti di forza | Limiti |
|------|---------|----------------|--------|
| **Claude Code** | Usage-based API / Max subscription | Il più forte in reasoning, hooks, plan mode, sub-agents | CLI-only, no GUI fleet |
| **Codex CLI** | Incluso in ChatGPT Pro/Team | Open-source, sandbox per task, parallel delegation | Cloud-only, latency, no local control |
| **Aider** | Free (BYO keys) | Git-aware, multi-file, 25k+ stars | CLI-only, no fleet, curva ripida |
| **Gemini CLI** | Free | Function calling, Gemini models | Più recente, meno maturo |
| **Cline** | Free (BYO keys) | VS Code extension, MCP support | Costi token escalano, single-agent |
| **Devin** | $20/mo + $2.25/ACU | Full autonomous agent, end-to-end | Costoso a scala, meglio per task junior |
| **GitHub Copilot** | Free-$39/mo | Ubiquo, agent mode + code review | Premium request limits, metered |
| **Kiro** | TBD | Agentic AI development | Molto nuovo |
| **OpenCode** | Free | Open-source terminal agent | Early stage |

**Gap**: Tutti eccellenti come singoli agenti, ma **nessuno ha una control surface per gestirne multipli**.

### 2.3 Competitor Diretti — Agent Fleet Management

Questa è la categoria emergente dove AgentsBoard compete direttamente.

| Tool | Tipo | Punti di forza | Limiti critici |
|------|------|----------------|----------------|
| **GitHub Agent HQ** | Cloud platform | Unified control plane across GitHub, VS Code, Mobile. Supporta Copilot, Claude, Codex. Enterprise governance, metrics dashboards. | **Locked a ecosistema GitHub**. Agent selection limitata a partner. Enterprise features dietro tier costosi ($19-39/user). No GPU rendering. No cost aggregation cross-provider. |
| **VS Code Multi-Agent (v1.109+)** | Editor feature | Agent Sessions view per Claude, Codex, Copilot. MCP Apps per UI interattiva. Parallel subagents. | **Non è un prodotto standalone** — è una feature dell'editor. No cost tracking. Orchestrazione limitata. |
| **Warp 2.0** | Terminal | Agent Management Panel, status tracking, permission guardrails, notifications. | **Terminal-only**. No code review, no file editor, no web dashboard. Limitato ad agent terminal-based. |
| **JetBrains Air** | IDE platform | Multi-agent (Codex, Claude, Gemini, Junie). Agent Client Protocol (ACP). Docker/worktree sandboxing. | **Preview quality**, macOS only, tied to JetBrains. No cost management. Pricing TBD. |
| **Composio Agent Orchestrator** | Open-source | Orchestratore per agent paralleli. Git worktree per agente, auto-branch, auto-PR. Dashboard localhost. Scala a 30 agent / 40 worktree. Auto-fix CI, handle review. | **Alpha stage**. Self-hosted only. Claude Code-focused. No polish. |
| **1Code (21st.dev, YC W26)** | SaaS | GUI per Claude Code + Codex. Git worktree isolation, cloud background execution, GitHub/Linear/Slack triggers. | **Molto nuovo** (YC W26). Thin orchestration layer. Limited agent support. |
| **AgentHub** | macOS native | Diff review, plan mode, pending changes preview, web preview, iOS sim, worktree remix, smart multi-launch. | **No GPU rendering**, no fleet dashboard, no cost tracking avanzato, no MCP, no recording, solo 2 provider. |
| **Cosmodrome** | macOS native | GPU Metal sub-4ms, fleet overview, activity log, MCP server, CLI, cost tracking, hooks authoritative, 4 provider, recording. | **No diff review**, no file editor, no web preview, no iOS sim, no smart launch, no plan view. |
| **Agent Deck** | Terminal TUI | Dashboard per Claude Code, Aider, Gemini CLI, Codex. | Lightweight, no cost tracking, no cloud, TUI only. |
| **Mission Control (builderz-labs)** | Open-source web | 32 panel dashboard (tasks, agents, logs, tokens, memory). SQLite, WebSocket + SSE. | **Alpha**, APIs instabili, self-hosted only, community piccola. |
| **SlayZone** | Web app | Kanban board + live terminal + browser + git per card. | Niche, info limitata. |

### 2.4 Agent Orchestration Frameworks (Infrastruttura)

| Framework | Tipo | Limiti per il nostro caso |
|-----------|------|--------------------------|
| **LangGraph** | Graph-based orchestration | Infrastruttura, no dev UX, no terminal |
| **CrewAI** | Role-based collaboration | Backend/API, no coding-specific GUI |
| **AutoGen** | Microsoft, conversational | Research-oriented, no GUI |
| **Google ADK** | Google agent kit | GCP-locked |

**Gap**: Sono per **costruire** sistemi multi-agente, non per **gestire** agenti di coding.

### 2.5 Observability & Cost Monitoring

| Tool | Tipo | Limiti |
|------|------|--------|
| **Agentic-metric** | TUI locale per agent monitoring | Solo monitoring, no management |
| **OpenCode Monitor** | Token/cost tracking con budgets | Solo costi, no fleet management |
| **Sentry AI Insights** | Dashboard AI workflows | Enterprise, no agent-specific |
| **Datadog LLM Observability** | Enterprise monitoring | Costoso, generalista |

**Gap**: Monitoring senza management. Nessuno combina **osservabilità + azione**.

### 2.6 Enterprise Implementations (Internal Tools)

| Company | Tool | Risultati |
|---------|------|-----------|
| **Spotify** | **Honk** | Background coding agent su fleet infra. 1,500+ PR merged, 650+ agent-generated PR/mese, 90% risparmio tempo su migrazioni |
| **Goldman Sachs** | Devin integration | Primo "AI employee" in hybrid workforce |

**Insight**: Le grandi aziende costruiscono internamente perché **nessun prodotto commerciale soddisfa le loro esigenze di fleet management**. Questo è il mercato.

---

## 3. Matrice Feature Completa

| Feature | Cursor | GitHub Agent HQ | Warp 2.0 | JetBrains Air | Composio | AgentHub | Cosmodrome | **AgentsBoard** |
|---------|:------:|:---------------:|:--------:|:--------------:|:--------:|:--------:|:----------:|:---------------:|
| Multi-agent fleet view | ✗ | **✓** | **✓** | **✓** | **✓** | Parziale | **✓** | **✓** |
| GPU-rendered terminals | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** |
| Diff review in-the-loop | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | ✗ | **✓** |
| Plan mode + annotations | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | ✗ | **✓** |
| Cost tracking fleet-wide | ✗ | Parziale | ✗ | ✗ | ✗ | Parziale | **✓** | **✓** |
| Cross-provider cost aggregation | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | Parziale | **✓** |
| Activity log strutturato | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** |
| MCP server / API | ✗ | API | ✗ | ACP | ✗ | ✗ | **✓** | **✓** |
| Session recording | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** |
| File explorer + editor | **✓** | ✗ | ✗ | **✓** | ✗ | **✓** | ✗ | **✓** |
| Web preview | **✓** | ✗ | ✗ | ✗ | ✗ | **✓** | ✗ | **✓** |
| iOS Simulator | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | ✗ | **✓** |
| Smart multi-launch | ✗ | Parziale | ✗ | ✗ | **✓** | **✓** | ✗ | **✓** |
| Intelligent task routing | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** |
| 4+ provider support | Multi | 3 | Multi | 4 | 1 | 2 | 4 | **4+** |
| Model detection | N/A | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** |
| Native macOS (no Electron) | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** | **✓** |
| Worktree remix + context | ✗ | ✗ | ✗ | **✓** | **✓** | **✓** | Parziale | **✓** |
| Cross-agent context transfer | ✗ | ✗ | ✗ | ✗ | ✗ | Parziale | ✗ | **✓** |
| Vim-style keybindings | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** |
| 100% privacy (zero telemetry) | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** | **✓** | **✓** |
| Verification chains (Agent A → B) | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **✓** |

**AgentsBoard è l'unico con ✓ su TUTTE le righe.**

---

## 4. I 7 Gap di Mercato

Basato su ricerca approfondita di cosa gli sviluppatori chiedono ma nessuno fornisce:

### Gap 1: Dashboard Agent-Agnostica con Orchestrazione Reale
GitHub Agent HQ è il più vicino ma locked nell'ecosistema GitHub. VS Code è una feature dell'editor. Warp è terminal-only. Composio è alpha. **Nessun prodotto commerciale offre un dashboard polished, agent-agnostic che funziona con QUALSIASI coding agent.**

### Gap 2: Cost Aggregation Cross-Provider
Nessuno unifica la spesa tra Anthropic API, OpenAI API, Cursor credits, Copilot premium requests, e Augment credits. La capacità di vedere "Feature X è costata $47 tra 3 agenti in 2 ore" **non esiste**.

### Gap 3: Context Transfer Cross-Agent
Se Claude Code scopre un bug pattern, quell'insight non è disponibile quando Codex prende un task correlato. Un **context layer condiviso che persiste tra agenti, sessioni e team** sarebbe un differenziatore enorme.

### Gap 4: Intelligent Task Routing
Nessun tool decide automaticamente "questo task dovrebbe andare a Claude Code (reasoning complesso) vs. Codex (parallel background) vs. Cursor (editing interattivo)." La selezione manuale è la norma.

### Gap 5: Fleet Operations a Livello Team
Spotify ha costruito Honk internamente perché **niente di commerciale esiste per fleet-scale agent operations** (centinaia di repo, migliaia di PR). Governance, audit trails, compliance a livello enterprise sono un gap.

### Gap 6: Il Layer "Manager"
Come Addy Osmani argomenta, gli agenti hanno bisogno di supervisione. Nessun prodotto fornisce **verification loops integrati, review chain automatiche** (Agent A implementa, Agent B revisiona, Agent C corregge) come feature configurabile.

### Gap 7: Cognitive Load Reduction
La ricerca mostra che il multitasking con AI agents causa **40% meno output e doppi i difetti**. Serve un sistema che gestisce il ciclo "prompt-wait-review-debug" tra agenti paralleli senza richiedere context switching costante.

---

## 5. Trend di Mercato

### 5.1 Il Paradigma Multi-Agent è Mainstream (2025-2026)
- Anthropic: Claude Code con sub-agents, hooks, plan mode
- OpenAI: Codex CLI open-source con sandbox per task
- Google: Gemini CLI con function calling
- GitHub: Agent HQ come "Mission Control" (marzo 2026)
- JetBrains: Air con multi-agent support
- Warp: 2.0 con Agent Management Panel
- Spotify: Honk con 650+ PR/mese generati da agenti
- Aider: 25k+ GitHub stars

### 5.2 I Costi Sono il Problema #1
- Claude Code Opus: $5-50+ per sessione
- 5 agenti in parallelo: $25-250/giorno
- Cursor Pro: $20/mo + credit overage
- Copilot: $0.04/premium request overage
- **Nessun tool aggrega i costi cross-provider**
- I team hanno bisogno di budget cap e alerting

### 5.3 Review-in-the-loop è l'Unico Modello Sostenibile
- 100% autonomia non funziona (Devin lo dimostra — meglio per task junior)
- Il modello vincente: **agente propone → umano approva → agente applica**
- "Your AI Coding Agents Need a Manager" — Addy Osmani (2026)
- AgentHub ha pending changes, ma senza fleet
- **Nessuno combina review + fleet**

### 5.4 MCP/ACP Come Standard di Programmabilità
- MCP (Anthropic) sta diventando lo standard
- ACP (JetBrains) come alternativa
- Cosmodrome ha MCP server — quasi unico nel mercato
- Next step: **agenti che controllano agenti** via protocolli standard

### 5.5 Performance Nativa vs. Electron Fatigue
- Ghostty e Zed hanno dimostrato che GPU = UX superiore
- Con 10+ terminali, GPU rendering non è lusso ma necessità
- VS Code/Cursor/Windsurf soffrono con molte sessioni aperte
- Solo Cosmodrome e Zed hanno GPU rendering tra i competitor

### 5.6 Context è il Bottleneck Reale
- "Context is AI Coding's Real Bottleneck in 2026" — The New Stack
- "Why Multitasking With AI Coding Agents Breaks Down" — DEV Community
- "Why AI Coding Tools Make Experienced Developers 19% Slower" — Augment Code
- La soluzione è **context management intelligente**, non più token

---

## 6. Target User

### Persona Primaria: "The Fleet Commander"
- **Ruolo**: Senior/Staff developer o Tech Lead
- **Comportamento**: Esegue 3-10 agenti AI in parallelo
- **Pain points**: Visibilità, costi, review centralizzata
- **Willingness to pay**: $20-50/mese
- **Esempio reale**: Usa Claude Code per refactoring, Codex per test generation, Aider per documentation, Gemini per review

### Persona Secondaria: "The AI-Native Developer"
- **Ruolo**: Full-stack developer, AI-first workflow
- **Comportamento**: Lancia agenti per backend, frontend, tests
- **Pain points**: Context switching, costi nascosti, review inefficiente
- **Willingness to pay**: $10-20/mese

### Persona Terziaria: "The Engineering Manager"
- **Ruolo**: Team lead / EM che supervisiona team con AI agents
- **Comportamento**: Vuole visibilità, governance, budget control
- **Pain points**: Zero visibilità, costi incontrollati, rischi qualità
- **Willingness to pay**: $30-100/mese per seat
- **Esempio reale**: Come il team di Spotify che ha costruito Honk

---

## 7. Sizing del Mercato

### TAM (Total Addressable Market)
- ~30M sviluppatori professionisti nel mondo
- ~40% usa AI tools nel 2026 → 12M
- TAM = 12M × $20/mese = **$2.88B/anno**

### SAM (Serviceable Addressable Market)
- Sviluppatori macOS: ~25% del totale → 3M
- Che usano AI agents CLI (non solo autocomplete): ~20% → 600K
- SAM = 600K × $25/mese = **$180M/anno**

### SOM (Serviceable Obtainable Market) — Anno 1
- Early adopters di multi-agent workflows: ~5% del SAM → 30K
- SOM = 30K × $25/mese = **$9M/anno**

### Comparabili
- Cursor: $82M+ ARR (2025), 360K paying users
- Windsurf: $82M ARR pre-acquisition
- Warp: $59M raised, pivoting to agentic
- Il mercato è reale e in crescita esplosiva

---

## 8. Strategia di Differenziazione

### 8.1 Unique Value Proposition
> **"L'unica app dove vedi tutti i tuoi agenti AI, approvi i loro cambiamenti, e controlli i costi — tutto in un'interfaccia nativa a 4ms."**

### 8.2 I 7 Moat

1. **Review-in-the-loop + Fleet**: L'unico tool che combina approvazione diff con fleet management
2. **Performance GPU nativa**: Metal rendering sub-4ms, impossibile con Electron
3. **MCP programmability**: Meta-orchestrazione — agenti che controllano agenti
4. **Cross-provider cost aggregation**: Antropic + OpenAI + Google in un dashboard
5. **Privacy totale**: Zero telemetry, tutto locale — per enterprise e security-conscious
6. **Intelligent task routing**: Auto-dispatch al provider giusto per il task
7. **Verification chains**: Agent A implementa → Agent B revisiona → Agent C corregge

### 8.3 Posizionamento nel Mercato

```
                    Fleet Management
                         ▲
                         │
         GitHub AQ  ●    │    ● AgentsBoard
                         │         (unique: review + fleet + GPU + cost)
    Composio ●           │
                         │    ● Cosmodrome
      Warp 2.0 ●         │
                         │
    ─────────────────────┼──────────────────► Code Review
                         │                    in-the-loop
         Cursor ●        │    ● AgentHub
                         │
    JetBrains Air ●      │
                         │
    Claude Code ●        │
                         │
```

- **Non è un IDE** (non compete con Cursor/Zed)
- **Non è un terminale** (non compete con Ghostty/Warp terminal)
- **Non è un framework** (non compete con CrewAI/LangGraph)
- **È un Mission Control** — la categoria: **AI Agent Fleet Management**
- Più simile a "Datadog per AI coding agents" — observability + management + orchestration

---

## 9. Go-to-Market

### Fase 1: Open Source Launch (Mese 1-3)
- Release GitHub, MIT license
- Post su Hacker News, Reddit r/programming, r/MacOS, r/ClaudeAI, r/LocalLLaMA
- Video demo su YouTube/Twitter/BlueSky
- Show HN con demo live
- Target: 1K GitHub stars, 500 utenti attivi

### Fase 2: Community & Integration (Mese 3-6)
- Discord community
- Provider plugin system (aggiungere nuovi agent senza PR)
- Theme marketplace
- MCP tool registry
- Integration: Linear, GitHub Issues, Slack (via MCP)
- Target: 5K stars, 2K utenti attivi

### Fase 3: Pro / Team (Mese 6-12)
- **AgentsBoard Pro**: team dashboards, cost budgets con alerts, usage analytics
- **AgentsBoard Team**: shared configurations, role-based access, audit logs
- Cloud sync opzionale (encrypted, opt-in)
- Priority support
- Target: 500 paying users, $150K ARR

### Fase 4: Enterprise (Mese 12-18)
- On-prem deployment
- SSO/SAML
- Compliance reporting
- Fleet-scale operations (à la Spotify Honk)
- Target: 10 enterprise accounts, $500K ARR

---

## 10. Rischi e Mitigazioni

| Rischio | Prob. | Impatto | Mitigazione |
|---------|:-----:|:-------:|-------------|
| **GitHub Agent HQ migliora** e copre i nostri gap | Alta | Alto | Siamo agent-agnostic e privacy-first. GitHub sarà sempre locked nel suo ecosistema. GPU rendering e 100% local sono impossibili per loro. |
| **Cursor/Zed aggiungono fleet** | Media | Alto | First-mover, depth of integration, provider-agnostic vs. loro single-provider |
| **JetBrains Air matura** | Media | Medio | Tied to JetBrains ecosystem, no GPU rendering, no cost tracking |
| **Composio matura** come OSS alternative | Media | Medio | Noi siamo nativi macOS con GPU, loro sono web-based. UX gap enorme. |
| **macOS-only limita il mercato** | Media | Medio | Power users sono >50% macOS. Cross-platform in v2 (Linux via Vulkan). |
| **AI agents diventano commodity** | Bassa | Alto | Trend opposto — stanno proliferando e differenziandosi. Più agenti = più bisogno di management. |
| **Open-source competitor emerge** | Media | Medio | Community building, velocità, depth. OSS è la nostra difesa — siamo OSS. |
| **Pricing dei modelli AI cambia** | Media | Basso | Noi tracciamo costi, non li generiamo. Provider-agnostic. |

---

## 11. Fonti

- [2026 Agentic Coding Trends Report — Anthropic](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)
- [Best AI Coding Agents for 2026 — Faros AI](https://www.faros.ai/blog/best-ai-coding-agents-2026)
- [10 Things Developers Want from Agentic IDEs — RedMonk](https://redmonk.com/kholterhoff/2025/12/22/10-things-developers-want-from-their-agentic-ides-in-2025/)
- [AI Coding Agents in 2026: Coherence Through Orchestration — Mike Mason](https://mikemason.ca/writing/ai-coding-agents-jan-2026/)
- [Your AI Coding Agents Need a Manager — Addy Osmani](https://addyosmani.com/blog/coding-agents-manager/)
- [Coding Agent Teams: The Next Frontier — DevOps.com](https://devops.com/coding-agent-teams-the-next-frontier-in-ai-assisted-software-development/)
- [VS Code: Your Home for Multi-Agent Development](https://code.visualstudio.com/blogs/2026/02/05/multi-agent-development)
- [Introducing Agent HQ — GitHub Blog](https://github.blog/news-insights/company-news/welcome-home-agents/)
- [How to Orchestrate Agents Using Mission Control — GitHub Blog](https://github.blog/ai-and-ml/github-copilot/how-to-orchestrate-agents-using-mission-control/)
- [Spotify's Background Coding Agent (Honk)](https://engineering.atspotify.com/2025/11/spotifys-background-coding-agent-part-1)
- [Spotify Cuts Migration Time by 90% with Claude — Anthropic](https://claude.com/customers/spotify)
- [Context is AI Coding's Real Bottleneck in 2026 — The New Stack](https://thenewstack.io/context-is-ai-codings-real-bottleneck-in-2026/)
- [Why Multitasking With AI Coding Agents Breaks Down — DEV Community](https://dev.to/johannesjo/why-multitasking-with-ai-coding-agents-breaks-down-and-how-i-fixed-it-2lm0)
- [Why AI Coding Tools Make Experienced Developers 19% Slower — Augment Code](https://www.augmentcode.com/guides/why-ai-coding-tools-make-experienced-developers-19-slower-and-how-to-fix-it)
- [Composio Open Sources Agent Orchestrator — MarkTechPost](https://www.marktechpost.com/2026/02/23/composio-open-sources-agent-orchestrator)
- [Warp: Agents with Full Terminal Control](https://www.warp.dev/agents)
- [JetBrains Air Public Preview — JetBrains Blog](https://blog.jetbrains.com/air/2026/03/air-launches-as-public-preview/)
- [1Code: Managing Multiple AI Coding Agents — DEV Community](https://dev.to/_46ea277e677b888e0cd13/1code-managing-multiple-ai-coding-agents-without-terminal-hell-14o4)
- [21 Agent Orchestration Tools — CIO](https://www.cio.com/article/4138739/21-agent-orchestration-tools-for-managing-your-ai-fleet.html)

---

## 12. Conclusione

Il mercato ha un gap chiaro e validato da dati di mercato reali:

1. **GitHub Agent HQ** dimostra che Big Tech riconosce la necessità → ma è locked
2. **Spotify Honk** dimostra che le enterprise costruiscono internamente → il prodotto non esiste
3. **Cursor/Windsurf a $82M ARR** dimostrano che i developer pagano per AI tools
4. **Context bottleneck** è il problema #1 citato in letteratura → cross-agent context è la soluzione
5. **40% productivity loss da multitasking** → un fleet manager riduce il cognitive load

AgentsBoard si posiziona all'intersezione di 3 trend convergenti:
- **Multi-agent proliferation** (più agenti = più bisogno di management)
- **Cost transparency** (spese fuori controllo = bisogno di aggregazione)
- **Native performance renaissance** (Electron fatigue = opportunità per GPU-native)

Il timing è perfetto. La categoria "AI Agent Fleet Management" sta nascendo ora. AgentsBoard può definirla.

---

*Documento preparato per il progetto AgentsBoard — Marzo 2026 v2.0*
