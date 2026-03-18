# AgentsBoard — Roadmap Completa

**Organizzazione**: Sprint da 1 settimana ciascuno
**Ogni step**: 1 skill/feature con descrizione esaustiva
**Principi**: SOLID obbligatorio in ogni step
**Agent assegnato**: indicato per ogni task

---

## FASE 1 — FONDAMENTA (Sprint 1-4)

Obiettivo: app che compila, si avvia, e ha l'infrastruttura base su cui tutto il resto viene costruito.

---

### Sprint 1 — Skeleton & Protocols

#### Step 1.1 — `foundation-protocols`
**Agent**: `backend-core`
**Descrizione**: Definire TUTTI i protocolli fondamentali del progetto. Questo è il contratto architetturale dell'intera applicazione. Nessuna implementazione — solo protocolli, tipi di dominio (struct/enum), e documentazione. Questo step applica ISP e DIP alla radice: ogni modulo futuro implementerà questi contratti senza mai dipendere da tipi concreti di altri moduli.

**Deliverables**:
- `Core/Agent/Protocols.swift`: `AgentDetectable`, `AgentStateObservable`, `AgentCostReportable`, `AgentControllable` — quattro protocolli separati (ISP) che insieme definiscono cosa un provider AI deve esporre. `AgentDetectable` rileva se un processo è un agente e di che tipo. `AgentStateObservable` emette stati (Working, NeedsInput, Error, Inactive). `AgentCostReportable` fornisce costi per sessione/task. `AgentControllable` permette di inviare input/comandi.
- `Core/Agent/Models.swift`: `AgentProvider` enum (claude, codex, aider, gemini, custom), `AgentState` enum con 4 stati, `AgentInfo` struct (provider, model, state, sessionId, projectPath, startTime), `ModelIdentifier` struct (name, provider, version).
- `Core/Terminal/Protocols.swift`: `TerminalSessionManaging` — crea/distrugge sessioni PTY, invia input, legge output. `TerminalDataReceiving` — callback per dati in arrivo dal PTY.
- `Core/Rendering/Protocols.swift`: `TerminalRenderable` — accetta una griglia di celle terminale e le renderizza. Separato dal terminale stesso (SRP).
- `Core/Fleet/Protocols.swift`: `FleetManaging` — aggrega sessioni cross-project, ordina per priorità, fornisce statistiche fleet-wide. `FleetObserving` — notifica cambiamenti nella flotta.
- `Core/Hooks/Protocols.swift`: `HookEventReceiving` — riceve eventi strutturati JSON dai hook di Claude Code. `HookEventParsing` — converte raw JSON in tipi di dominio.
- `Core/MCP/Protocols.swift`: `MCPToolRegistrable` — registra un tool MCP con nome, schema, e handler. `MCPServerManaging` — avvia/ferma il server JSON-RPC.
- `Core/Config/Protocols.swift`: `ConfigProviding` — legge configurazione utente e progetto. `ThemeProviding` — carica e fornisce temi.
- `Core/Project/Protocols.swift`: `ProjectManaging` — CRUD su progetti. `SessionGrouping` — raggruppa sessioni per progetto.
- `Core/CostTracking/Protocols.swift`: `CostSource` — qualsiasi cosa che emette dati di costo. `CostAggregating` — aggrega costi a vari livelli (sessione → progetto → fleet).
- `Core/Recording/Protocols.swift`: `SessionRecordable` — avvia/ferma/esporta registrazione. `SessionPlayable` — riproduce registrazioni.
- `Core/Persistence/Protocols.swift`: `PersistenceProviding` — astrazione su SQLite/GRDB. Nessun tipo in Core/ importa GRDB direttamente.

**Test**: Compilazione dei protocolli. Test che verificano che i protocolli sono implementabili con mock.

---

#### Step 1.2 — `app-skeleton`
**Agent**: `macos-core`
**Descrizione**: Creare l'app macOS che compila e si avvia mostrando una finestra vuota. Questo è il composition root (DIP): il punto dove i protocolli vengono wired alle implementazioni concrete. L'app deve avviarsi in <200ms, mostrare una finestra con titolo "AgentsBoard", e uscire pulitamente. Include la struttura di window management che supporterà menu bar mode e toolbar mode.

**Deliverables**:
- `App/AgentsBoardApp.swift`: Entry point `@main`. Crea la `CompositionRoot` che wira tutti i protocolli alle implementazioni. Inietta le dipendenze nel `WindowManager`.
- `App/CompositionRoot.swift`: Factory che crea tutte le implementazioni concrete e le wira ai protocolli. Unico punto dove `import GRDB`, `import SwiftTerm`, `import Yams` appaiono. Tutto il resto del codice usa solo protocolli (DIP).
- `App/WindowManager.swift`: Gestisce finestra principale, supporta futura menu bar mode. Usa `NSWindow` direttamente (AppKit) con contenuto SwiftUI via `NSHostingView`.
- `UI/RootView.swift`: SwiftUI view vuota con placeholder "AgentsBoard" che sarà sostituita dal layout system.

**Test**: L'app compila con `swift build`. Nessun warning. Zero import circolari tra moduli.

---

#### Step 1.3 — `config-system`
**Agent**: `backend-core`
**Descrizione**: Implementare il sistema di configurazione completo. L'app deve leggere configurazione da tre livelli in cascata: defaults built-in → user config (`~/.config/agentsboard/config.yml`) → project config (`agentsboard.yml`). Il project config sovrascrive il user config che sovrascrive i defaults. Il sistema usa Yams per parsing ma è wrappato dietro `ConfigProviding` (DIP). La configurazione è @Observable così la UI si aggiorna automaticamente al cambiamento. Include hot-reload: se il file YAML cambia su disco, la config si ricarica senza restart.

**Deliverables**:
- `Core/Config/AppConfig.swift`: Struct `AppConfig` con tutte le opzioni: theme (String), font family/size, notifications (Bool), scrollback (Int), layout (LayoutMode enum), keymap (Dictionary), terminal settings.
- `Core/Config/ConfigManager.swift`: Implementa `ConfigProviding`. Legge YAML via Yams (wrappato dietro `YAMLParsing` protocol). Merge a 3 livelli. FileSystem watcher per hot-reload. @Observable.
- `Core/Config/ProjectConfig.swift`: Struct `ProjectConfig` con: name, sessions array (name, command, workdir, auto_start, restart policy), env vars.
- `Core/Config/YAMLParser.swift`: Wrapper su Yams dietro `YAMLParsing` protocol. Unico file che importa Yams.
- Test: Unit test con YAML di esempio. Test merge cascata. Test hot-reload con file mock.

---

#### Step 1.4 — `persistence-layer`
**Agent**: `backend-core`
**Descrizione**: Implementare il layer di persistenza SQLite via GRDB.swift, completamente wrappato dietro `PersistenceProviding` (DIP). Questo layer salva: nomi custom delle sessioni, stato finestra, preferenze UI, cronologia costi, log attività. Il database vive in `~/Library/Application Support/AgentsBoard/agentsboard.db`. Include migrazioni versioneate per evoluzione schema futura. GRDB non viene mai importato al di fuori di questo modulo.

**Deliverables**:
- `Core/Persistence/DatabaseManager.swift`: Implementa `PersistenceProviding`. Crea/apre DB, gestisce migrazioni, espone CRUD generico via protocollo.
- `Core/Persistence/Migrations.swift`: Schema versioning. v1: tables per sessions, projects, cost_entries, activity_events, preferences.
- `Core/Persistence/GRDBWrapper.swift`: Unico file che importa GRDB. Espone operazioni via protocol types, mai tipi GRDB.
- Test: Unit test con database in-memory. Test migrazioni. Test CRUD per ogni tabella.

---

### Sprint 2 — Terminal Engine

#### Step 2.1 — `pty-manager`
**Agent**: `macos-core`
**Descrizione**: Implementare il gestore PTY (pseudo-terminal) che crea e gestisce processi child con terminale associato. Ogni sessione AI agent gira in un PTY separato. Il PTY manager usa `forkpty()` POSIX per creare il processo, `kqueue` per multiplexare I/O da N sessioni su un singolo thread. Il design è event-driven: quando dati arrivano su un PTY, vengono routati alla sessione corretta via callback protocol. Questo è il cuore I/O dell'app — deve essere rock-solid, mai crashare, gestire child process death gracefully.

**Deliverables**:
- `Core/Terminal/PTYProcess.swift`: Struct che wrappa un singolo processo PTY. Crea via `forkpty()`, gestisce `SIGCHLD`, espone file descriptor per I/O. Cleanup su deinit.
- `Core/Terminal/PTYMultiplexer.swift`: Singola istanza, gira su un thread dedicato (I/O thread). Usa `kqueue` per monitorare N file descriptor. Quando dati disponibili, legge e dispatch al `TerminalDataReceiving` delegate della sessione. Scala a 50+ sessioni.
- `Core/Terminal/TerminalSession.swift`: Implementa `TerminalSessionManaging`. Wrappa SwiftTerm `Terminal` + `PTYProcess`. Gestisce resize (SIGWINCH), input da utente, output dal processo. @Observable per stato (running, exited, error).
- Test: Test con processo `echo` come child. Test multiplexer con 5+ processi concorrenti. Test graceful handling di process exit.

---

#### Step 2.2 — `metal-renderer`
**Agent**: `macos-core`
**Descrizione**: Implementare il renderer GPU Metal che disegna TUTTI i terminali in una singola `MTKView` usando viewport scissoring. Ogni terminale è un rettangolo nella view — il renderer clippa al viewport di ciascuno e disegna la griglia di caratteri. Usa un glyph atlas condiviso (texture con tutti i caratteri pre-renderizzati) per evitare rasterizzazione per-frame. Triple-buffered vertex data per evitare stall GPU/CPU. Zero allocazioni per-frame. Target: sub-4ms per frame, 60fps stabile anche con 20+ terminali visibili.

**Deliverables**:
- `Core/Rendering/MetalRenderer.swift`: Implementa `TerminalRenderable`. Inizializza Metal device, command queue, pipeline state. Metodo `render(sessions: [TerminalViewport])` disegna tutti i terminali.
- `Core/Rendering/GlyphAtlas.swift`: Carica font, rasterizza tutti i glifi in una MTLTexture atlas. Cache per font/size. Supporta SF Mono, Menlo, e font custom da config.
- `Core/Rendering/TerminalViewport.swift`: Struct che definisce: rect nella MTKView, griglia di celle (carattere + foreground + background + attributi), cursore.
- `Core/Rendering/Shaders.metal`: Vertex + fragment shader. Vertex shader posiziona quad per ogni cella. Fragment shader sampla dal glyph atlas e applica colori.
- `Core/Rendering/VertexBufferPool.swift`: Triple buffer pool. Frame N scrive nel buffer (N % 3) mentre GPU legge da (N-1 % 3). Nessun lock contention.
- Test: Test che il renderer inizializza senza crash. Test glyph atlas con font di sistema. Benchmark frame time.

---

#### Step 2.3 — `terminal-integration`
**Agent**: `macos-core`
**Descrizione**: Collegare PTY manager, SwiftTerm parser, e Metal renderer in un terminale funzionante end-to-end. L'utente digita → input va al PTY → output torna → SwiftTerm parsa le sequenze VT → griglia di celle aggiornata → Metal renderizza. Include: scroll buffer (configurabile, default 10K righe), selezione testo, copia/incolla, resize terminale, gestione colori ANSI 256 + TrueColor, attributi testo (bold, italic, underline, strikethrough).

**Deliverables**:
- `Core/Terminal/VTParser.swift`: Wrapper su SwiftTerm dietro protocol. Converte stream di bytes in griglia di celle terminal con attributi.
- `Core/Terminal/TerminalGrid.swift`: Griglia di `TerminalCell` (character, fg, bg, attributes). Scroll buffer circolare. Operazioni: scroll up/down, clear, resize.
- `UI/SessionMonitor/TerminalView.swift`: NSViewRepresentable che hostra la MTKView. Gestisce keyboard input (NSEvent → bytes al PTY), mouse events per selezione, scroll gesture.
- Integrazione in `RootView`: una singola sessione terminale visibile e funzionante. Puoi lanciare `zsh` e usarlo.
- Test: Integration test — lancia `echo hello`, verifica che "hello" appare nella griglia. Test resize. Test scroll buffer.

---

### Sprint 3 — Agent Detection & State

#### Step 3.1 — `agent-provider-abstraction`
**Agent**: `backend-core`
**Descrizione**: Implementare l'astrazione provider che permette di aggiungere nuovi agenti AI senza modificare codice esistente (OCP). Ogni provider è un tipo separato che conforma ai 4 protocolli ISP definiti nello Step 1.1. Il sistema di detection analizza il processo in esecuzione nel PTY e determina automaticamente: (1) se è un agente AI, (2) quale provider, (3) quale modello sta usando. La detection avviene sia via analisi del comando di lancio che via parsing dell'output del terminale. Non si usa MAI `switch` sul tipo di provider — tutto è polimorfismo via protocollo.

**Deliverables**:
- `Core/Agent/AgentDetector.swift`: Implementa `AgentDetectable`. Analizza command line e output iniziale. Ritorna `AgentInfo?`. Usa chain-of-responsibility: prova ogni detector registrato in ordine fino a match.
- `Core/Agent/Providers/ClaudeCodeProvider.swift`: Conforma a tutti e 4 i protocolli. Detection: cerca "claude" nel comando, parsa output per modello (Opus/Sonnet/Haiku). State: analizza output per "Thinking", "Tool", "Approval", "Waiting". Cost: parsa token count dall'output.
- `Core/Agent/Providers/CodexProvider.swift`: Detection: cerca "codex" nel comando. State: analizza output per stati Codex. Cost: parsa token usage.
- `Core/Agent/Providers/AiderProvider.swift`: Detection: cerca "aider" nel comando. Parsa output per modello e costi.
- `Core/Agent/Providers/GeminiProvider.swift`: Detection: cerca "gemini" nel comando. Parsa output per modello.
- `Core/Agent/ProviderRegistry.swift`: Registry dove si registrano i provider (OCP — aggiungi senza modificare). Il detector itera il registry.
- Test: Unit test per ogni provider con output di esempio. Test registry con provider custom mock.

---

#### Step 3.2 — `agent-state-machine`
**Agent**: `backend-core`
**Descrizione**: Implementare la state machine che traccia lo stato di ogni agente in tempo reale. Lo stato transiziona tra: Working (verde — sta pensando o eseguendo tool), NeedsInput (giallo — aspetta approvazione utente), Error (rosso — ha incontrato un errore), Inactive (grigio — idle o processo non-agente). Le transizioni sono basate su: (1) eventi hooks se disponibili (authoritative), (2) regex parsing dell'output terminale (fallback). La state machine emette eventi osservabili così UI e Fleet possono reagire. Include debouncing per evitare flickering tra stati.

**Deliverables**:
- `Core/Agent/AgentStateMachine.swift`: @Observable. Gestisce transizioni di stato con validazione (non tutti le transizioni sono permesse). Emette `stateDidChange` con old/new state. Debounce configurabile (default 500ms).
- `Core/Agent/StateDetectors/HookBasedDetector.swift`: Se hooks disponibili, usa eventi strutturati JSON per determinare lo stato. Authoritative — sovrascrive sempre regex.
- `Core/Agent/StateDetectors/RegexBasedDetector.swift`: Fallback. Pattern matching sull'output del terminale per inferire lo stato. Meno affidabile ma universale.
- `Core/Agent/StateDetectors/ModelDetector.swift`: Identifica il modello LLM in uso (Opus 4, Sonnet 4, GPT-4, Gemini 2.5 Pro, etc.) dall'output o dalle API.
- `Core/Agent/AgentSession.swift`: Combina `TerminalSession` + `AgentStateMachine` + `AgentInfo`. È il tipo che rappresenta "una sessione con un agente AI in esecuzione". @Observable.
- Test: Test state machine transitions. Test che hooks sovrascrivono regex. Test debouncing. Test model detection con output di esempio.

---

#### Step 3.3 — `claude-hooks-integration`
**Agent**: `backend-core`
**Descrizione**: Implementare l'integrazione profonda con Claude Code hooks. Claude Code emette eventi strutturati JSON per ogni azione: file read, file write, command execution, sub-agent spawn, tool use approval, cost delta. AgentsBoard riceve questi eventi via Unix socket (come CosmodromeHook). Gli eventi hooks sono la sorgente AUTORITATIVA — quando disponibili, sovrascrivono qualsiasi inferenza da regex. Questo è il differenziatore chiave per l'integrazione Claude Code: non stiamo indovinando cosa fa l'agente, lo sappiamo con certezza.

**Deliverables**:
- `Core/Hooks/HookServer.swift`: Unix socket server che ascolta eventi da Claude Code hook binary. Parsa JSON, converte in `HookEvent` domain types, dispatch ai subscriber.
- `Core/Hooks/HookEvent.swift`: Enum con tutti i tipi di evento: `toolUse(name, input, output)`, `fileRead(path)`, `fileWrite(path, diff)`, `commandExec(command, exitCode)`, `subAgentSpawn(id)`, `costDelta(inputTokens, outputTokens, cost)`, `approval(tool, status)`.
- `Core/Hooks/HookBinary.swift`: Il binary che Claude Code invoca come hook. Riceve l'evento, lo forwarda al socket del server AgentsBoard. Compilato separatamente.
- `Core/Hooks/HookInstaller.swift`: Configura Claude Code per usare il nostro hook binary. Modifica `~/.claude/settings.json` per aggiungere il hook.
- Test: Test server con eventi mock. Test parsing di ogni tipo di evento. Test fallback quando hooks non disponibili.

---

### Sprint 4 — Fleet Management Core

#### Step 4.1 — `fleet-aggregator`
**Agent**: `backend-core`
**Descrizione**: Implementare il fleet aggregator che gestisce TUTTE le sessioni agente cross-project. Il fleet è il cuore dell'app — aggrega dati da N progetti, ciascuno con M sessioni. Fornisce: lista di tutte le sessioni ordinate per priorità (NeedsInput > Error > Working > Inactive), statistiche aggregate (totale sessioni, costi, errori), filtri (per progetto, per provider, per stato). È @Observable così FleetOverview UI si aggiorna in real-time. Il fleet NON gestisce sessioni individuali (SRP) — le osserva e aggrega.

**Deliverables**:
- `Core/Fleet/FleetManager.swift`: Implementa `FleetManaging`. Mantiene registry di tutte le `AgentSession`. Ordina per priorità. Calcola statistiche. @Observable.
- `Core/Fleet/FleetStats.swift`: Struct con: totalSessions, activeSessions, needsInputCount, errorCount, totalCost, costPerProject, costPerProvider, sessionsByState.
- `Core/Fleet/FleetSorter.swift`: Logica di sorting separata (SRP). Priority: NeedsInput (urgente) → Error → Working → Inactive. Dentro ogni gruppo, ordine per timestamp ultimo evento.
- `Core/Fleet/FleetFilter.swift`: Filtri componibili: per progetto, per provider, per stato, per modello, per range di costo. Combinabili con AND.
- Test: Test sorting con sessioni miste. Test filtri. Test statistiche. Test con 50+ sessioni mock per performance.

---

#### Step 4.2 — `project-manager`
**Agent**: `backend-core`
**Descrizione**: Implementare il project manager che organizza sessioni per progetto. Un progetto è definito da un `agentsboard.yml` nella root del progetto, oppure creato implicitamente quando si lancia un agente in una directory. Il project manager: scopre progetti (scan filesystem per `agentsboard.yml`), li persiste in SQLite, gestisce lifecycle delle sessioni (auto-start, restart policy), e mappa path → progetto. Supporta git worktree: un progetto può avere worktree multipli, ciascuno con sessioni separate.

**Deliverables**:
- `Core/Project/ProjectManager.swift`: Implementa `ProjectManaging`. Scan per `agentsboard.yml`. CRUD progetti. Persiste via `PersistenceProviding`.
- `Core/Project/Project.swift`: @Observable. name, path, sessions array, worktrees, config, isActive.
- `Core/Project/SessionGroup.swift`: Raggruppa sessioni per progetto. Implementa `SessionGrouping`.
- `Core/Project/WorktreeManager.swift`: Crea/elimina git worktree via `git worktree add/remove`. Lista worktree esistenti.
- Test: Test con `agentsboard.yml` di esempio. Test discovery. Test worktree (con git repo di test).

---

#### Step 4.3 — `cost-tracking-engine`
**Agent**: `backend-core`
**Descrizione**: Implementare il motore di cost tracking che aggrega costi a tutti i livelli: per-token → per-task → per-sessione → per-progetto → fleet-wide. I costi arrivano da: (1) hook events (autoritativi per Claude Code), (2) parsing output terminale (fallback), (3) API calls se disponibili. Il motore calcola: costo corrente, costo per ora, costo medio per task, burn rate, proiezione giornaliera. Persiste tutto in SQLite per storico. Supporta diversi modelli di pricing per provider (token-based, credit-based, ACU-based). Include alert quando il costo supera soglie configurabili.

**Deliverables**:
- `Core/CostTracking/CostEngine.swift`: Implementa `CostAggregating`. Riceve `CostEntry` da qualsiasi `CostSource`. Aggrega a tutti i livelli. @Observable.
- `Core/CostTracking/CostEntry.swift`: Struct: provider, model, inputTokens, outputTokens, cost (USD), timestamp, sessionId, taskId (opzionale).
- `Core/CostTracking/PricingModels/TokenPricing.swift`: Calcolo costo per provider token-based (Anthropic, OpenAI). Tabella prezzi aggiornabile.
- `Core/CostTracking/PricingModels/CreditPricing.swift`: Conversione crediti → USD (Cursor, Augment).
- `Core/CostTracking/CostAlert.swift`: Alert quando costo supera soglia (per-session, per-day, per-project). Configurabile via YAML.
- `Core/CostTracking/CostHistory.swift`: Query su storico costi da SQLite. Aggregazioni per giorno/settimana/mese. Dati per sparkline UI.
- Test: Test aggregazione multi-livello. Test pricing per ogni provider. Test alert. Test storico con query temporali.

---

## FASE 2 — UI CORE (Sprint 5-8)

Obiettivo: interfaccia utente completa con fleet overview, session monitoring, e layout system.

---

### Sprint 5 — Layout System & Session Cards

#### Step 5.1 — `layout-engine`
**Agent**: `frontend-ui`
**Descrizione**: Implementare il sistema di layout che organizza le session card nella finestra principale. Supporta 5 modalità: Single (una sessione fullscreen), List (lista verticale con card ridimensionabili), 2-Column (griglia 2 colonne), 3-Column (griglia 3 colonne), Focus (una sessione grande + miniature laterali). L'utente può switchare layout via toolbar o Cmd+1/2/3/4/5. Le card sono ridimensionabili in List mode con drag handle. Il layout si adatta al resize della finestra. Ogni layout è un tipo separato che conforma a `LayoutProviding` (OCP — aggiungere layout senza modificare il layout engine).

**Deliverables**:
- `UI/Layout/LayoutEngine.swift`: Calcola posizioni e dimensioni per N card dato il tipo di layout e le dimensioni della finestra.
- `UI/Layout/Layouts/SingleLayout.swift`, `ListLayout.swift`, `TwoColumnLayout.swift`, `ThreeColumnLayout.swift`, `FocusLayout.swift`: Ciascuno conforma a `LayoutProviding`. Logica di posizionamento specifica.
- `UI/Layout/LayoutSwitcher.swift`: UI per selezione layout. Toolbar buttons + keyboard shortcuts.
- `UI/Layout/CardContainer.swift`: SwiftUI view che posiziona le card secondo il layout attivo. Animazione di transizione tra layout.
- Test: Test posizionamento per ogni layout con varie dimensioni finestra. Test resize. Test transizione.

---

#### Step 5.2 — `session-card`
**Agent**: `frontend-ui`
**Descrizione**: Implementare la session card — il componente UI che rappresenta una singola sessione agente. La card mostra: header (nome sessione, provider icon, modello, stato con colore), terminale embedded (Metal rendered), footer (costo corrente, durata, ultima azione). La card ha bordo colorato per stato (verde/giallo/rosso/grigio). Click sulla card → focus/maximize. Doppio click → fullscreen. Right-click → context menu (rename, kill, restart, remix, record). La card è il componente più usato dell'app — deve essere performante e visivamente chiaro.

**Deliverables**:
- `UI/SessionMonitor/SessionCardView.swift`: SwiftUI view. Header + terminal + footer. Stato come bordo colorato. Animazione transizione stato.
- `UI/SessionMonitor/SessionCardHeader.swift`: Provider icon, nome (editabile inline), model badge, stato indicator (dot con colore + label).
- `UI/SessionMonitor/SessionCardFooter.swift`: Costo live, durata, ultima azione (es. "Wrote 3 files", "Running tests").
- `UI/SessionMonitor/SessionContextMenu.swift`: Right-click menu: Rename, Kill Session, Restart, Remix to Worktree, Start Recording, Copy Session ID.
- `UI/SessionMonitor/SessionCardViewModel.swift`: @Observable view model che consuma `AgentSession` dal Core. Espone solo ciò che la card view necessita (ISP).
- Test: Preview con mock data per ogni stato. Test view model con sessione mock.

---

#### Step 5.3 — `sidebar`
**Agent**: `frontend-ui`
**Descrizione**: Implementare la sidebar che mostra la lista di progetti e sessioni in una struttura ad albero. Ogni progetto è un nodo espandibile con le sue sessioni come figli. Le sessioni mostrano: nome, provider icon, stato (dot colorato). I progetti mostrano: nome, conteggio sessioni attive, costo aggregato. La sidebar supporta: drag-and-drop per riordinare, filtro di ricerca, collapse/expand progetti, badge per "needs input" count. La sidebar è collapsabile con Cmd+B. Ha sezione separata per "All Sessions" (flat list) e "By Project" (tree).

**Deliverables**:
- `UI/Sidebar/SidebarView.swift`: Contiene segmented control (All / By Project), search field, lista progetti/sessioni.
- `UI/Sidebar/ProjectTreeItem.swift`: Nodo progetto espandibile. Mostra nome, count attivi, costo, badge needs-input.
- `UI/Sidebar/SessionListItem.swift`: Riga sessione. Provider icon, nome, stato dot, modello.
- `UI/Sidebar/SidebarViewModel.swift`: @Observable. Consuma `FleetManaging` per dati. Gestisce espansione/collapse, filtro, ordinamento.
- Test: Preview con dati mock. Test filtro. Test ordinamento.

---

### Sprint 6 — Fleet Overview & Activity Log

#### Step 6.1 — `fleet-overview-ui`
**Agent**: `frontend-ui`
**Descrizione**: Implementare la Fleet Overview — il dashboard full-screen (Cmd+Shift+F) che mostra tutti gli agenti cross-project. Questo è la vista DEFAULT dell'app: apri AgentsBoard e vedi subito lo stato di tutti i tuoi agenti. Il dashboard mostra: card per ogni agente ordinate per priorità (NeedsInput in cima, rosso per errori), metriche aggregate in header (totale agenti, costi, errori), filtri rapidi per provider/stato/progetto. Le card in fleet overview sono più compatte delle session card — mostrano stato, provider, modello, costo, ultima azione, ma NO terminale embedded (sarebbe troppo per 10+ agenti). Click su una card → naviga alla sessione nel monitor view.

**Deliverables**:
- `UI/FleetOverview/FleetOverviewView.swift`: Full-screen overlay con header metriche + griglia di agent cards. Attivato con Cmd+Shift+F.
- `UI/FleetOverview/FleetHeaderView.swift`: Barra metriche: Total Agents (count), Active (count), Needs Input (badge urgente), Total Cost ($), Errors (count con alert).
- `UI/FleetOverview/FleetAgentCard.swift`: Card compatta: provider icon, nome, modello, stato (colore + label), costo sessione, tempo attivo, ultima azione. Priorità visiva per NeedsInput/Error.
- `UI/FleetOverview/FleetFilterBar.swift`: Filtri: All | Claude | Codex | Aider | Gemini × All States | Working | Needs Input | Error | Inactive. Combinabili.
- `UI/FleetOverview/FleetOverviewViewModel.swift`: Consuma `FleetManaging`. Sort, filter, aggregate. @Observable.
- Test: Preview con 10+ agenti mock in vari stati. Test sorting. Test filtri.

---

#### Step 6.2 — `activity-log`
**Agent**: `frontend-ui` + `backend-core`
**Descrizione**: Implementare l'Activity Log — timeline strutturata (Cmd+L) di TUTTO ciò che gli agenti hanno fatto. Ogni entry mostra: timestamp, agente, tipo di azione (file changed, command run, error, cost), dettagli. Filtrabile per: finestra temporale (ultima ora, oggi, tutto), categoria (files, commands, errors), sessione specifica. Le entry sono raggruppate per sessione con collapse/expand. Le più recenti in cima. Include highlighting per errori (rosso) e azioni che richiedono attenzione (giallo). I dati vengono da: hook events (Claude), regex parsing (altri provider), e cost engine.

**Deliverables**:
- `Core/Activity/ActivityEvent.swift`: Struct: timestamp, sessionId, agentInfo, eventType (fileChanged, commandRun, error, costDelta, approval, subAgentSpawn), details (associatedValues per tipo), cost (opzionale).
- `Core/Activity/ActivityLogger.swift`: Riceve eventi da hooks, state machine, cost engine. Persiste in SQLite. Query per filtri temporali e categoriali.
- `UI/ActivityLog/ActivityLogView.swift`: Full-screen overlay. Header con filtri. Timeline scrollabile. Entry raggruppate per sessione.
- `UI/ActivityLog/ActivityEntryView.swift`: Singola entry: icona tipo, timestamp, sessione, dettagli. Colore per severità.
- `UI/ActivityLog/ActivityFilterBar.swift`: Filtri temporali + categoriali + per sessione.
- `UI/ActivityLog/ActivityLogViewModel.swift`: Query `ActivityLogger`, applica filtri, @Observable.
- Test: Test logger con eventi mock. Test query temporali. Preview con dati mock.

---

#### Step 6.3 — `notification-system`
**Agent**: `frontend-ui` + `macos-core`
**Descrizione**: Implementare il sistema di notifiche che avvisa l'utente quando un agente richiede attenzione. Usa notifiche macOS native (UNUserNotificationCenter) per: agente in attesa di input/approvazione, agente in errore, sessione completata, costo supera soglia. Include suoni configurabili (attivabili/disattivabili da config). Le notifiche sono actionable: click → focus sulla sessione. Include anche notifiche in-app: badge su sidebar items, pulsazione del bordo della card, counter in menu bar icon. Non spamma: raggruppa notifiche multiple dello stesso tipo.

**Deliverables**:
- `Core/Notifications/NotificationManager.swift`: Implementa `NotificationManaging` protocol. Riceve eventi da fleet/state machine/cost engine. Decide cosa notificare. Rate limiting e grouping.
- `UI/Notifications/InAppBadge.swift`: Badge rosso con counter per sidebar e menu bar.
- `UI/Notifications/CardPulse.swift`: Animazione pulsante sul bordo della card quando needs input.
- `App/SystemNotifications.swift`: Bridge a UNUserNotificationCenter. Registra categorie e azioni. Handle click → focus sessione.
- Test: Test rate limiting. Test grouping. Test che azioni navigano alla sessione corretta.

---

### Sprint 7 — Command Palette & Keyboard

#### Step 7.1 — `command-palette`
**Agent**: `frontend-ui`
**Descrizione**: Implementare il Command Palette (Cmd+K) — l'interfaccia di accesso rapido a TUTTE le azioni dell'app. È una search bar overlay in stile Spotlight/VS Code che mostra risultati in tempo reale mentre si digita. Le categorie di risultati: Sessioni (filtra per nome/provider/stato), Progetti (filtra per nome), Azioni (New Session, Kill All, Toggle Layout, Open Fleet, Open Activity Log, etc.), File (Cmd+P shortcut alternativo). Fuzzy matching sui nomi. Keyboard navigation: frecce per selezionare, Enter per eseguire, Esc per chiudere. MRU (most recently used) in cima quando vuoto.

**Deliverables**:
- `UI/CommandPalette/CommandPaletteView.swift`: Overlay con search field + lista risultati. Blur background. Animazione appear/dismiss.
- `UI/CommandPalette/CommandItem.swift`: Singolo risultato: icona, titolo, sottotitolo, shortcut badge, categoria.
- `UI/CommandPalette/CommandRegistry.swift`: Registry di tutti i comandi disponibili. Ogni modulo registra i suoi comandi (OCP). Comandi: struct con name, category, shortcut, action closure.
- `UI/CommandPalette/FuzzyMatcher.swift`: Algoritmo fuzzy matching. Scoring: exact > prefix > substring > fuzzy. Case insensitive. Highlights match positions.
- `UI/CommandPalette/CommandPaletteViewModel.swift`: @Observable. Query registry con termine di ricerca. Sort per score + MRU. Keyboard navigation state.
- Test: Test fuzzy matcher con vari input. Test registry con comandi mock. Test MRU ordering.

---

#### Step 7.2 — `keyboard-system`
**Agent**: `frontend-ui` + `macos-core`
**Descrizione**: Implementare il sistema di keyboard shortcuts completamente configurabile. Ogni shortcut è definito come binding: azione → key combo. I bindings di default sono built-in ma l'utente può sovrascriverli via config YAML. Supporta: single key combos (Cmd+K), chord sequences (Ctrl+Space poi j/k per navigare — vim mode), modifier combos. Il sistema intercetta NSEvent a livello di window e dispatcha all'azione registrata. Include vim-style command mode: Ctrl+Space entra in command mode dove j/k naviga sessioni, h/l naviga progetti, n=new, x=kill, f=focus, p=palette. Command mode ha un indicator visivo (barra in basso).

**Deliverables**:
- `Core/Keybindings/KeyBinding.swift`: Struct: action (String), modifiers (NSEvent.ModifierFlags), key (String/keyCode), isChord (Bool), chordSequence.
- `Core/Keybindings/KeybindingManager.swift`: Registry di tutti i bindings. Carica da config YAML. Merge default + user override. Resolve conflitti.
- `App/KeyEventHandler.swift`: NSEvent monitor a livello window. Intercetta key events, matcha con bindings, dispatch azioni. Gestisce chord state.
- `UI/VimMode/VimModeManager.swift`: State machine per command mode. Ctrl+Space toggle. j/k/h/l/n/x/f/p/a/g bindings. Mostra indicator bar.
- `UI/VimMode/VimModeIndicator.swift`: Barra in basso che mostra "-- COMMAND MODE --" e il pending chord.
- Test: Test binding resolution. Test chord sequences. Test conflitti. Test vim mode transitions.

---

### Sprint 8 — Theme Engine & Polishing

#### Step 8.1 — `theme-engine`
**Agent**: `frontend-ui`
**Descrizione**: Implementare il theme engine completo con hot-reload. I temi sono file YAML in `~/Library/Application Support/AgentsBoard/themes/`. Ogni tema definisce: colori terminale (16 ANSI + bright variants + foreground/background), colori UI (accent, sidebar bg, card bg, border, text primary/secondary), font override, spacing. Il tema attivo è selezionabile da config. Built-in temi: dark (default), light, solarized-dark, solarized-light, monokai, dracula. Hot-reload: quando un file tema cambia su disco, l'app aggiorna immediatamente senza restart. L'utente può creare temi custom copiando e modificando un file YAML.

**Deliverables**:
- `Core/Config/Theme.swift`: Struct con tutti i colori e parametri. Decodable da YAML. Default values per ogni campo mancante.
- `Core/Config/ThemeManager.swift`: Implementa `ThemeProviding`. Carica temi da directory. File watcher per hot-reload. Fallback a default se tema corrotto.
- `UI/Themes/ThemeEnvironment.swift`: SwiftUI `EnvironmentKey` per il tema corrente. Tutti i colori UI derivano dal tema.
- `UI/Themes/ThemedColor.swift`: Extension su `Color` che risolve dal tema attivo.
- `Resources/Themes/dark.yml`, `light.yml`, `solarized-dark.yml`, `monokai.yml`, `dracula.yml`: Temi built-in.
- Test: Test caricamento YAML. Test hot-reload. Test fallback. Test che tutti i colori sono risolvibili.

---

#### Step 8.2 — `menu-bar-mode`
**Agent**: `macos-core`
**Descrizione**: Implementare la modalità menu bar come alternativa alla finestra principale. L'app può vivere nella menu bar di macOS come icona persistente. Click sull'icona → popover con mini fleet overview (stati agenti, badge needs-input). Il popover è più compatto del fleet overview full — mostra solo: lista agenti con stato, costo totale, e quick actions (focus session, open full app). L'utente può scegliere tra "window mode" e "menu bar mode" da config. In menu bar mode, l'icona mostra un badge numerico per agenti che richiedono input. Opzione: apri finestra principale da menu bar con "Open AgentsBoard".

**Deliverables**:
- `App/MenuBarController.swift`: NSStatusItem con icona custom. Badge numerico per needs-input count. Gestisce popover.
- `UI/MenuBar/MenuBarPopover.swift`: Popover compatto: lista agenti (icona + nome + stato), costo totale, bottoni (Open App, New Session, Quit).
- `UI/MenuBar/MenuBarAgentRow.swift`: Riga agente nel popover: provider icon, nome, stato dot, azione rapida (focus/approve).
- `App/AppModeManager.swift`: Switch tra window mode e menu bar mode. Persiste scelta in config.
- Test: Test che badge si aggiorna con stato fleet. Test switch tra modalità.

---

## FASE 3 — CODE REVIEW & IDE (Sprint 9-12)

Obiettivo: diff review, file explorer, editor, plan mode — le feature "IDE-lite" che differenziano AgentsBoard.

---

### Sprint 9 — Diff Review System

#### Step 9.1 — `diff-engine`
**Agent**: `backend-core`
**Descrizione**: Implementare il motore diff che calcola e rappresenta le differenze tra versioni di file. Il diff engine riceve: (1) hook events `fileWrite(path, diff)` da Claude Code con diff già calcolati, (2) per altri provider, calcola diff confrontando file pre/post modifica usando l'algoritmo Myers diff. Il risultato è un modello strutturato di `DiffHunk` che la UI può renderizzare. Supporta: unified diff, side-by-side diff, inline diff. Gestisce: file nuovi (tutto verde), file eliminati (tutto rosso), file modificati (hunks con context lines), file rinominati, file binari (solo indicazione, no diff content).

**Deliverables**:
- `Core/DiffEngine/DiffCalculator.swift`: Implementa algoritmo Myers diff. Input: old content, new content. Output: array di `DiffHunk`.
- `Core/DiffEngine/DiffHunk.swift`: Struct: startLineOld, startLineNew, lines array di `DiffLine` (added/removed/context + content).
- `Core/DiffEngine/DiffResult.swift`: Struct: filePath, oldPath (per rename), changeType (added/modified/deleted/renamed/binary), hunks, stats (additions, deletions).
- `Core/DiffEngine/PendingChange.swift`: Struct che rappresenta un cambiamento proposto da un agente che NON è ancora stato applicato. Include: sessionId, diffResult, timestamp, status (pending/approved/rejected/applied).
- `Core/DiffEngine/PendingChangesManager.swift`: Gestisce la coda di cambiamenti pending. Approve → applica il file. Reject → scarta. Batch approve/reject. @Observable.
- Test: Test diff con vari scenari (add, modify, delete, rename). Test pending changes lifecycle. Test con file grandi (performance).

---

#### Step 9.2 — `diff-review-ui`
**Agent**: `frontend-ui`
**Descrizione**: Implementare la UI di diff review — la feature chiave che nessun competitor ha in un fleet manager. Quando un agente propone di modificare un file, l'utente vede il diff PRIMA che venga applicato e può: approvare, rifiutare, o commentare. La UI supporta: split-pane (old a sinistra, new a destra) e unified view. Syntax highlighting per entrambi i pane basato sul tipo di file. Numeri di riga clickabili per aggiungere commenti inline. Commenti vengono inviati all'agente come feedback. Batch mode: review di multiple file changes in sequenza con "Approve All" / "Reject All". Navigation tra hunks con Cmd+↑/↓.

**Deliverables**:
- `UI/DiffReview/DiffReviewView.swift`: Container con toolbar (approve/reject/comment/batch) e area diff. Toggle split/unified.
- `UI/DiffReview/SplitDiffView.swift`: Due pane affiancati con scroll sincronizzato. Highlighting added (verde) / removed (rosso) / context.
- `UI/DiffReview/UnifiedDiffView.swift`: Singolo pane con linee colorate. Prefisso +/- per added/removed.
- `UI/DiffReview/DiffLineView.swift`: Singola linea diff con syntax highlighting e line number. Clickabile per commento inline.
- `UI/DiffReview/InlineCommentView.swift`: Text field che appare sotto la linea clickata. Enter → invia commento all'agente. Shift+Enter → newline.
- `UI/DiffReview/BatchReviewBar.swift`: Barra in basso con: conteggio pending changes, progress, "Approve All", "Reject All", "Next" (Cmd+Return).
- `UI/DiffReview/DiffReviewViewModel.swift`: Consuma `PendingChangesManager`. Gestisce navigazione tra changes. Invia feedback alla sessione.
- Test: Preview con diff mock multi-hunk. Test batch operations. Test invio commenti.

---

#### Step 9.3 — `pending-changes-flow`
**Agent**: `backend-core` + `frontend-ui`
**Descrizione**: Implementare il flusso completo end-to-end dei pending changes. Quando un agente Claude Code usa il tool Edit/Write/MultiEdit, il hook event arriva → AgentsBoard intercetta → il cambiamento diventa "pending" → l'utente vede la notifica (card pulsa giallo) → apre diff review → approva o rifiuta → se approvato, il cambiamento viene applicato al file → l'agente riceve conferma → il cambiamento appare nell'activity log con status. Per provider senza hooks (Codex, Aider, Gemini), AgentsBoard può opzionalmente monitorare il filesystem per cambiamenti e mostrare un diff post-hoc (review dopo applicazione, meno potente ma comunque utile).

**Deliverables**:
- `Core/Hooks/PendingChangeInterceptor.swift`: Si registra come handler per hook events di tipo `fileWrite`. Crea `PendingChange` invece di lasciar applicare il file.
- `Core/Agent/FileSystemWatcher.swift`: Per provider senza hooks. Monitora directory del progetto per cambiamenti file. Crea diff post-hoc.
- Integrazione con `NotificationManager`: notifica quando ci sono pending changes.
- Integrazione con `ActivityLogger`: logga approve/reject con dettagli.
- Integrazione con `AgentStateMachine`: stato "NeedsInput" quando ci sono pending changes.
- `UI/SessionMonitor/PendingChangeBadge.swift`: Badge sulla session card che mostra conteggio pending changes.
- Test: Integration test full flow con mock hooks. Test filesystem watcher. Test che approve applica il file.

---

### Sprint 10 — File Explorer & Editor

#### Step 10.1 — `file-explorer`
**Agent**: `frontend-ui`
**Descrizione**: Implementare il file explorer che mostra la struttura del progetto come albero di file/directory. Il file explorer vive nella sidebar (tab alternativo a sessions list) o in un pannello laterale dedicato. Mostra: icone per tipo file (Swift, Python, JS, YAML, etc.), indicatori per file modificati dagli agenti (dot o highlight), file ignorati da .gitignore sono dimmed. Funzionalità: click → apri in editor, right-click → context menu (open, copy path, reveal in Finder, show git history), Cmd+P → quick open con fuzzy search su nomi file. Lazy loading per directory grandi. Rispetta .gitignore di default (toggle per mostrare tutto).

**Deliverables**:
- `UI/FileExplorer/FileExplorerView.swift`: Tree view con expand/collapse. Lazy loading.
- `UI/FileExplorer/FileTreeNode.swift`: Nodo albero: tipo (file/dir), nome, path, icon, isModifiedByAgent, isGitIgnored.
- `UI/FileExplorer/FileTreeBuilder.swift`: Costruisce albero da filesystem. Rispetta .gitignore. Marca file modificati.
- `UI/FileExplorer/FileIconProvider.swift`: Mappa estensione → icona SF Symbol. Extensible (OCP).
- `UI/FileExplorer/QuickOpenView.swift`: Overlay Cmd+P. Fuzzy search su tutti i file del progetto. Preview del file selezionato.
- `UI/FileExplorer/FileExplorerViewModel.swift`: @Observable. Gestisce stato albero, espansione, filtro.
- Test: Test tree building con directory mock. Test .gitignore filtering. Test fuzzy search.

---

#### Step 10.2 — `code-editor`
**Agent**: `frontend-ui`
**Descrizione**: Implementare l'editor di codice con syntax highlighting. L'editor è read-write e permette di modificare file del progetto direttamente da AgentsBoard. Non è un IDE completo — è un editor leggero per quick edits e review. Syntax highlighting per: Swift, Python, JavaScript/TypeScript, YAML, JSON, Markdown, Shell, Go, Rust, HTML, CSS. L'editor usa NSTextView (AppKit) wrappato in SwiftUI per performance e text system nativo macOS. Features: line numbers, current line highlight, bracket matching, auto-indent, Cmd+S per salvare, Cmd+Z/Y undo/redo, search in file (Cmd+F), go to line (Cmd+G).

**Deliverables**:
- `UI/Editor/CodeEditorView.swift`: NSViewRepresentable wrapping NSTextView. Occupa il pannello destro o si apre in tab.
- `UI/Editor/SyntaxHighlighter.swift`: Tokenizer per-linguaggio (regex-based, non LSP). Applica attributi al NSAttributedString. Highlighting incrementale (solo linee modificate).
- `UI/Editor/LanguageDefinition.swift`: Protocol per definire un linguaggio. Conformers per Swift, Python, JS/TS, YAML, JSON, Markdown, Shell, Go, Rust, HTML, CSS.
- `UI/Editor/LineNumberGutter.swift`: Gutter con numeri di linea. Highlight linea corrente. Click per selezione linea.
- `UI/Editor/EditorViewModel.swift`: @Observable. Gestisce file aperto, dirty state, undo/redo stack, search.
- `UI/Editor/EditorSearchBar.swift`: Cmd+F search bar inline. Find/Replace. Match count. Navigate matches.
- Test: Test syntax highlighting per ogni linguaggio con snippet. Test save/load. Test search.

---

### Sprint 11 — Plan Mode & Web Preview

#### Step 11.1 — `plan-mode`
**Agent**: `backend-core` + `frontend-ui`
**Descrizione**: Implementare Plan Mode — la modalità read-only dove Claude Code analizza il codice e propone un piano senza eseguire o modificare nulla. Plan mode si attiva con Shift+Tab o dal command palette. Quando attivo, Claude Code viene lanciato con `--permission-mode plan` che permette solo lettura file e analisi. Il piano viene renderizzato come Markdown nel Plan View con: heading strutturati, code blocks con syntax highlighting, checklist di task proposti. L'utente può: annotare singole righe del piano con commenti, approvare/rifiutare singoli step, inviare batch feedback all'agente. Solo per Claude Code (Codex non ha un flag equivalente).

**Deliverables**:
- `Core/Agent/PlanMode.swift`: Gestisce attivazione/disattivazione plan mode. Lancia Claude con flag corretto. Traccia stato.
- `UI/PlanView/PlanView.swift`: Rendering Markdown del piano. Struttura con heading navigabile.
- `UI/PlanView/PlanStepView.swift`: Singolo step del piano: checkbox (approvato/rifiutato), contenuto markdown, annotation area.
- `UI/PlanView/PlanAnnotation.swift`: Commento inline su un singolo step. Text field con submit.
- `UI/PlanView/PlanFeedbackBar.swift`: Barra in basso: "Approve Plan", "Reject Plan", "Send Feedback". Raccoglie tutte le annotazioni e le invia come batch.
- `UI/PlanView/MarkdownRenderer.swift`: Converte Markdown → SwiftUI views. Supporta: headings, paragraphs, code blocks (con syntax highlighting), lists, checkboxes, links.
- Test: Test rendering markdown con vari contenuti. Test annotazioni. Test batch feedback.

---

#### Step 11.2 — `web-preview`
**Agent**: `frontend-ui` + `macos-core`
**Descrizione**: Implementare Web Preview — la vista che mostra l'output di un dev server del progetto dell'utente dentro AgentsBoard. Quando un agente sta lavorando su un progetto web (React, Next.js, Vue, Svelte, etc.), AgentsBoard può mostrare il risultato in un pannello preview. Il sistema: (1) rileva automaticamente il framework dal progetto (package.json, framework files), (2) trova o suggerisce il comando dev server, (3) mostra il risultato in una WKWebView embedded, (4) auto-reload quando file cambiano. L'utente può anche inserire un URL manualmente. Questa è l'UNICA web view nell'app — tutte le altre UI sono native SwiftUI/AppKit.

**Deliverables**:
- `UI/WebPreview/WebPreviewView.swift`: WKWebView wrappata in NSViewRepresentable. URL bar editabile. Refresh button. Open in browser button.
- `UI/WebPreview/FrameworkDetector.swift`: Analizza progetto per detectare: React (package.json + react dep), Next.js, Vue, Svelte, Vite, etc. Suggerisce porta dev server.
- `UI/WebPreview/DevServerMonitor.swift`: Verifica se il dev server è in esecuzione. Se no, suggerisce di avviarlo. Monitora la porta per readiness.
- `UI/WebPreview/LiveReloadWatcher.swift`: File system watcher su src/ del progetto. Quando file cambiano → reload WKWebView.
- Test: Test framework detection con package.json mock. Test URL loading.

---

#### Step 11.3 — `ios-simulator`
**Agent**: `macos-core`
**Descrizione**: Implementare l'integrazione con iOS Simulator. Quando un agente lavora su un progetto iOS/Swift, l'utente può: vedere la lista dei simulatori disponibili (booted e non), selezionare un simulatore come "run destination", triggerare build + install + launch direttamente dalla session card. Usa `xcrun simctl` per controllare il simulatore e `xcodebuild` per build. Lo stato del build è visibile nella session card (building, installing, running, failed). Include: selezione dello scheme Xcode, log di build in un terminale dedicato.

**Deliverables**:
- `Core/iOS/SimulatorManager.swift`: Lista simulatori via `xcrun simctl list -j`. Boot/shutdown. Install app. Launch app.
- `Core/iOS/XcodeBuildRunner.swift`: Esegue `xcodebuild` con scheme e destination. Stream output a terminale. Parse errori.
- `UI/iOSSimulator/SimulatorPicker.swift`: UI per selezionare simulatore e scheme. Lista dropdown.
- `UI/iOSSimulator/BuildStatusView.swift`: Indicatore build nella session card: spinner durante build, check per success, X per failure.
- Test: Test parsing output simctl. Test parsing build errors.

---

### Sprint 12 — Diagram Renderer & Search

#### Step 12.1 — `mermaid-renderer`
**Agent**: `frontend-ui`
**Descrizione**: Implementare il rendering nativo di diagrammi Mermaid. Quando un agente include un blocco Mermaid nel suo output (```mermaid), AgentsBoard lo renderizza come diagramma visivo inline nel terminale o nel plan view. Il rendering usa una WKWebView headless con Mermaid.js per generare SVG, che viene poi convertito in NSImage per display nativo. Supporta: flowchart, sequence diagram, class diagram, state diagram, ER diagram, gantt chart. Include: export come PNG/SVG, zoom, pan. Il rendering è asincrono e non blocca il thread principale.

**Deliverables**:
- `UI/DiagramRenderer/MermaidDetector.swift`: Parsa output terminale per blocchi ```mermaid. Estrae il contenuto.
- `UI/DiagramRenderer/MermaidRenderer.swift`: WKWebView headless che carica Mermaid.js, renderizza il diagramma, cattura come SVG/immagine.
- `UI/DiagramRenderer/DiagramView.swift`: View che mostra il diagramma renderizzato. Zoom (scroll), pan (drag), toolbar (export PNG, export SVG, copy).
- `UI/DiagramRenderer/DiagramCache.swift`: Cache diagrammi renderizzati per evitare re-render. Invalidazione quando content cambia.
- Test: Test detection con vari blocchi mermaid. Test rendering con diagrammi semplici.

---

#### Step 12.2 — `global-search`
**Agent**: `frontend-ui` + `backend-core`
**Descrizione**: Implementare Global Search — la capacità di cercare attraverso TUTTI i file delle sessioni, output dei terminali, e activity log. Cmd+Shift+F apre la search view. La ricerca è full-text con ranking dei risultati per rilevanza. I risultati sono raggruppati per: sessione (output terminale), file progetto (contenuto file), activity log (eventi). Ciascun risultato mostra: file/sessione, linea con match highlighted, context (linee prima/dopo). Click su risultato → naviga a quel punto (sessione terminale, file nell'editor, o entry nel log). La ricerca è incrementale (risultati si aggiornano mentre si digita) con debouncing.

**Deliverables**:
- `Core/Search/SearchEngine.swift`: Full-text search su: file progetto, output sessioni (scroll buffer), activity log. Ranking per rilevanza. Debounce.
- `Core/Search/SearchResult.swift`: Struct: source (file/session/activity), path/sessionId, line number, matchedLine, contextBefore, contextAfter, score.
- `UI/Search/GlobalSearchView.swift`: Overlay con search field e risultati raggruppati. Tab per source type.
- `UI/Search/SearchResultRow.swift`: Riga risultato con highlighted match, file path, line number.
- `UI/Search/GlobalSearchViewModel.swift`: @Observable. Debounced query. Raggruppamento. Navigazione a risultato.
- Test: Test search con contenuto mock. Test ranking. Test debouncing.

---

## FASE 4 — ORCHESTRATION & PROGRAMMABILITY (Sprint 13-16)

Obiettivo: MCP server, CLI, smart launch, recording, session remix.

---

### Sprint 13 — MCP Server & CLI

#### Step 13.1 — `mcp-server`
**Agent**: `backend-core`
**Descrizione**: Implementare il server MCP (Model Context Protocol) che espone AgentsBoard come tool controllabile programmaticamente. Il server usa JSON-RPC 2.0 over stdio. Qualsiasi agente AI o script che parla MCP può: listare progetti e sessioni, query stato agenti, inviare input a sessioni, controllare recording, ottenere statistiche fleet, leggere activity log. Questo abilita la "meta-orchestrazione" — un agente Claude che usa AgentsBoard come tool per gestire altri agenti. Il server è extensible: nuovi tool si aggiungono conformando a `MCPToolRegistrable` (OCP), senza modificare il server core.

**Deliverables**:
- `Core/MCP/MCPServer.swift`: Implementa `MCPServerManaging`. Avvia server JSON-RPC 2.0 over stdio. Registra tool. Dispatch richieste. Handle errors.
- `Core/MCP/MCPProtocol.swift`: Types per JSON-RPC: `MCPRequest`, `MCPResponse`, `MCPError`, `MCPTool` (name, description, inputSchema).
- `Core/MCP/Tools/ListProjectsTool.swift`: Tool `list_projects`. Ritorna array di progetti con sessioni.
- `Core/MCP/Tools/ListSessionsTool.swift`: Tool `list_sessions`. Filtri per progetto/stato/provider.
- `Core/MCP/Tools/GetSessionContentTool.swift`: Tool `get_session_content`. Ritorna ultimo output della sessione.
- `Core/MCP/Tools/SendInputTool.swift`: Tool `send_input`. Invia testo a una sessione specifica.
- `Core/MCP/Tools/GetAgentStatesTool.swift`: Tool `get_agent_states`. Ritorna stati di tutti gli agenti.
- `Core/MCP/Tools/FocusSessionTool.swift`: Tool `focus_session`. Porta la sessione in primo piano.
- `Core/MCP/Tools/RecordingTools.swift`: Tool `start_recording`, `stop_recording`. Controlla recording per sessione.
- `Core/MCP/Tools/GetFleetStatsTool.swift`: Tool `get_fleet_stats`. Ritorna statistiche aggregate.
- `Core/MCP/Tools/GetActivityLogTool.swift`: Tool `get_activity_log`. Ritorna eventi filtrabili.
- Test: Test per ogni tool con request/response mock. Test error handling. Test tool registration.

---

#### Step 13.2 — `cli-control`
**Agent**: `backend-core`
**Descrizione**: Implementare `agentsctl` — il tool CLI che controlla un'istanza AgentsBoard in esecuzione via Unix socket. L'utente apre un terminale qualsiasi e può: `agentsctl list` per vedere sessioni, `agentsctl status` per stato fleet, `agentsctl focus <session>` per portare una sessione in primo piano, `agentsctl send <session> "text"` per inviare input, `agentsctl cost` per vedere costi, `agentsctl record start/stop <session>` per controllare recording. Il CLI comunica con AgentsBoard via Unix socket in `~/Library/Application Support/AgentsBoard/agentsctl.sock`. Il protocollo è lo stesso JSON-RPC del MCP server.

**Deliverables**:
- `Core/Control/ControlServer.swift`: Unix socket server in AgentsBoard. Accetta connessioni da agentsctl. Dispatch comandi al MCP server interno.
- `CLI/AgentsCtl.swift`: Entry point del CLI. Parse argomenti. Connessione al socket. Send request, print response.
- `CLI/Commands/ListCommand.swift`: `agentsctl list [--project X] [--state Y] [--provider Z]`
- `CLI/Commands/StatusCommand.swift`: `agentsctl status` — overview fleet con ASCII art.
- `CLI/Commands/FocusCommand.swift`: `agentsctl focus <session-id-or-name>`
- `CLI/Commands/SendCommand.swift`: `agentsctl send <session> "text"`
- `CLI/Commands/CostCommand.swift`: `agentsctl cost [--session X] [--project Y] [--fleet]`
- `CLI/Commands/RecordCommand.swift`: `agentsctl record start|stop <session>`
- Test: Test parsing argomenti. Test connessione socket con mock server.

---

### Sprint 14 — Smart Launch & Orchestration

#### Step 14.1 — `multi-session-launcher`
**Agent**: `backend-core` + `frontend-ui`
**Descrizione**: Implementare il Multi-Session Launcher che permette di avviare N sessioni agente in parallelo con un singolo click o comando. L'utente può: (1) Manual mode — seleziona provider, comando, workdir per ogni sessione e lancia tutte insieme, (2) Config mode — lancia tutte le sessioni definite in `agentsboard.yml` con auto_start: true, (3) Smart mode — descrive un obiettivo ad alto livello e un agente AI pianifica la distribuzione dei task tra N agenti. Il launcher mostra un'anteprima delle sessioni da lanciare prima di confermare. Gestisce errori di lancio gracefully (se una sessione fallisce, le altre continuano).

**Deliverables**:
- `UI/Launcher/LauncherView.swift`: Sheet modale con 3 tab (Manual, Config, Smart). Anteprima sessioni. Confirm/Cancel.
- `UI/Launcher/ManualLauncherTab.swift`: Form per aggiungere sessioni: provider picker, command field, workdir picker, nome. + button per aggiungere più sessioni.
- `UI/Launcher/ConfigLauncherTab.swift`: Mostra sessioni da `agentsboard.yml`. Toggle per attivare/disattivare ciascuna. Edit inline.
- `UI/Launcher/SmartLauncherTab.swift`: Text area per obiettivo. "Plan" button → chiama un agente AI per pianificare. Mostra piano proposto. Confirm per lanciare.
- `Core/Orchestration/SessionLauncher.swift`: Crea N `AgentSession` in parallelo. Error handling per-sessione. Progress callback.
- `Core/Orchestration/SmartPlanner.swift`: Usa un agente AI (via provider configurato) per analizzare l'obiettivo e proporre distribuzione task.
- Test: Test lancio multiplo con mock. Test error handling. Test config parsing.

---

#### Step 14.2 — `session-remix`
**Agent**: `backend-core` + `frontend-ui`
**Descrizione**: Implementare Session Remix — la capacità di "forkare" una sessione in un git worktree isolato con il contesto della sessione originale trasferito. L'utente seleziona una sessione, sceglie "Remix" dal context menu, e AgentsBoard: (1) crea un nuovo git worktree dal branch corrente, (2) apre una nuova sessione con un provider (anche diverso dall'originale), (3) inietta il transcript/contesto della sessione originale nel prompt iniziale della nuova sessione, (4) l'utente lavora nel worktree isolato senza interferire con la sessione originale. Questo permette: esplorare alternative, testare approcci diversi, cambiare provider mantenendo contesto.

**Deliverables**:
- `Core/Project/WorktreeManager.swift`: (estensione) Crea worktree con nome custom e branch tracking.
- `Core/Orchestration/SessionRemixer.swift`: Gestisce il flow di remix: crea worktree, estrae contesto dalla sessione originale (ultimi N messaggi/azioni), prepara prompt iniziale per la nuova sessione, lancia la nuova sessione nel worktree.
- `Core/Orchestration/ContextExtractor.swift`: Estrae contesto utile da una sessione: file modificati, comandi eseguiti, errori, decisioni chiave. Riassume per il prompt della nuova sessione.
- `UI/Remix/RemixSheet.swift`: UI per configurare il remix: provider picker, branch name, quanto contesto trasferire (last N actions, full transcript, summary only).
- Test: Test creazione worktree. Test estrazione contesto. Test flow completo con mock.

---

### Sprint 15 — Session Recording & Playback

#### Step 15.1 — `recording-engine`
**Agent**: `backend-core`
**Descrizione**: Implementare il motore di recording che registra sessioni terminale in formato asciicast v2. Una registrazione cattura: ogni byte di output con timestamp preciso (millisecondi), dimensioni terminale e resize events, metadata (provider, modello, progetto, costo finale). Il recording può essere avviato/fermato per sessione via: UI (button sulla card), CLI (agentsctl record), MCP (start_recording tool). Le registrazioni sono salvate in `~/Library/Application Support/AgentsBoard/recordings/`. Il formato asciicast v2 è compatibile con asciinema per playback esterno. Include anche export come GIF animata per sharing.

**Deliverables**:
- `Core/Recording/RecordingEngine.swift`: Implementa `SessionRecordable`. Intercetta output del PTY e scrive nel file asciicast. Start/stop/pause per sessione. Salva metadata.
- `Core/Recording/AsciicastWriter.swift`: Scrive formato asciicast v2: header JSON + event lines (timestamp, type, data). Flush periodico.
- `Core/Recording/RecordingMetadata.swift`: Struct: sessionId, provider, model, project, startTime, endTime, totalCost, terminalSize.
- `Core/Recording/RecordingManager.swift`: Gestisce tutte le registrazioni attive. Lista registrazioni salvate. Delete. Export.
- `Core/Recording/GifExporter.swift`: Converte asciicast → GIF animata. Usa rendering interno (no dipendenze esterne).
- Test: Test write asciicast. Test metadata. Test start/stop lifecycle.

---

#### Step 15.2 — `playback-viewer`
**Agent**: `frontend-ui`
**Descrizione**: Implementare il viewer per playback di sessioni registrate. L'utente può: aprire una registrazione dalla lista, vederla riprodotta nel terminale Metal renderer (stessa qualità della sessione live), controllare playback (play/pause, speed 0.5x/1x/2x/4x, skip forward/back, seek con slider timeline). La timeline mostra marker per eventi significativi (file changes, errors, approvals) così l'utente può saltare direttamente ai momenti importanti. Utile per: post-mortem di sessioni problematiche, demo per colleghi, onboarding (mostra come usare gli agenti), review di lavoro notturno degli agenti.

**Deliverables**:
- `Core/Recording/PlaybackEngine.swift`: Implementa `SessionPlayable`. Legge asciicast, emette bytes al ritmo registrato (rispettando timestamps). Speed control.
- `UI/Recording/PlaybackView.swift`: Terminale Metal + controlli playback (play/pause, speed, timeline slider).
- `UI/Recording/PlaybackTimeline.swift`: Slider orizzontale con marker per eventi. Seek. Tempo corrente / totale.
- `UI/Recording/RecordingBrowser.swift`: Lista di tutte le registrazioni. Filtri per progetto/provider/data. Thumbnail (primo frame).
- `UI/Recording/PlaybackViewModel.swift`: @Observable. Controlla PlaybackEngine. Gestisce timeline state.
- Test: Test playback con asciicast di esempio. Test speed control. Test seek.

---

### Sprint 16 — Intelligent Task Routing

#### Step 16.1 — `task-router`
**Agent**: `backend-core`
**Descrizione**: Implementare l'Intelligent Task Router — il sistema che suggerisce automaticamente quale provider/modello è più adatto per un dato task. Basato su euristiche configurabili: task di deep reasoning/refactoring → Claude Code Opus, task di generazione bulk (test, docs) → Codex o Claude Sonnet, task di review → Gemini o Claude, task interattivi → qualsiasi con bassa latency. L'utente può accettare il suggerimento o sovrascriverlo. Le euristiche apprendono dalle scelte dell'utente (store in SQLite). Il router è invocabile da: Smart Launcher, Command Palette, MCP tool. Non è AI-based (no LLM call per routing) — usa regole e statistiche.

**Deliverables**:
- `Core/Orchestration/TaskRouter.swift`: Analizza descrizione task + contesto (linguaggio, dimensione codebase, tipo di cambiamento). Suggerisce provider + modello.
- `Core/Orchestration/RoutingRules.swift`: Regole configurabili: condizione → provider/model suggerito. Default rules built-in. User override via config.
- `Core/Orchestration/RoutingHistory.swift`: Traccia scelte utente (suggerito vs scelto). Aggiusta scoring basato su preferenze osservate.
- `Core/Orchestration/TaskClassifier.swift`: Classifica task per tipo: refactoring, bug-fix, feature, test-generation, documentation, review, migration.
- Test: Test classificazione. Test routing rules. Test learning da storico.

---

#### Step 16.2 — `verification-chains`
**Agent**: `backend-core`
**Descrizione**: Implementare Verification Chains — la feature dove Agent A implementa, Agent B revisiona, e Agent C corregge. L'utente definisce una chain: step 1 (implement) → step 2 (review) → step 3 (fix based on review). Ogni step usa un provider/modello (potenzialmente diverso). Il flusso è: step 1 completa → output diventa input di step 2 → step 2 completa → output diventa input di step 3. L'utente può intervenire tra step (approve/modify/skip). Questo implementa il pattern "manager" suggerito da Addy Osmani: gli agenti si supervisionano a vicenda. Configurabile via YAML o UI.

**Deliverables**:
- `Core/Orchestration/VerificationChain.swift`: Definisce una chain di step. Ogni step: provider, modello, prompt template, timeout, approval required (Bool).
- `Core/Orchestration/ChainExecutor.swift`: Esegue la chain step-by-step. Trasferisce output → input. Pausa per approval se configurato. Handle timeout/errori.
- `Core/Orchestration/ChainTemplates.swift`: Chain pre-definite: "Implement & Review" (2 step), "Implement, Review, Fix" (3 step), "Test & Fix" (2 step).
- `UI/Orchestration/ChainEditorView.swift`: UI per creare/editare chain. Drag-and-drop step. Provider/model picker per step.
- `UI/Orchestration/ChainProgressView.swift`: Mostra progresso della chain: step completati, step corrente, step rimanenti.
- Test: Test esecuzione chain con mock providers. Test interruzione. Test timeout.

---

## FASE 5 — POLISH & RELEASE (Sprint 17-20)

Obiettivo: drag-and-drop, cross-agent context, performance optimization, packaging, release.

---

### Sprint 17 — Drag & Drop & Attachments

#### Step 17.1 — `drag-drop-system`
**Agent**: `frontend-ui` + `macos-core`
**Descrizione**: Implementare drag-and-drop di file e immagini nelle sessioni agente. L'utente può trascinare un file dal Finder (o dal file explorer di AgentsBoard) su una session card, e il file viene allegato come contesto per l'agente. Per Claude Code: il file viene passato via path nel prompt. Per immagini: vengono convertite in base64 e incluse nel prompt (vision support). Supporta: file singoli, file multipli, directory (vengono espanse), immagini (PNG, JPG, SVG), file di testo. Include feedback visivo: drop zone highlight, anteprima file, progress indicator per file grandi.

**Deliverables**:
- `UI/DragDrop/DropZoneView.swift`: Overlay sulla session card quando drag entra. Highlight verde per drop valido, rosso per non supportato.
- `UI/DragDrop/FileAttachment.swift`: Struct: path, filename, fileType, size, thumbnailImage (per immagini).
- `UI/DragDrop/AttachmentProcessor.swift`: Converte file droppati in formato adatto al provider. Path per testo, base64 per immagini.
- `UI/DragDrop/AttachmentPreview.swift`: Preview dei file allegati prima dell'invio. Remove button per ciascuno.
- `Core/Agent/AttachmentSender.swift`: Inietta file nel prompt dell'agente nel formato corretto per il provider.
- Test: Test drag di file di testo. Test drag di immagine. Test file multipli.

---

### Sprint 18 — Cross-Agent Context

#### Step 18.1 — `context-bridge`
**Agent**: `backend-core`
**Descrizione**: Implementare il Context Bridge — il sistema che permette di trasferire contesto tra agenti/sessioni diverse. Quando Claude Code scopre un bug pattern in una sessione, quell'insight può essere condiviso con una sessione Codex che lavora sullo stesso progetto. Il Context Bridge mantiene un "project knowledge graph" per progetto: decisioni architetturali, pattern scoperti, file critici, bug noti. Ogni sessione contribuisce automaticamente (via hook events o output parsing). Il contesto è iniettabile nel prompt di nuove sessioni. Privacy-first: il knowledge graph è locale, per-progetto, mai sincronizzato.

**Deliverables**:
- `Core/Context/ContextBridge.swift`: Gestisce il knowledge graph per progetto. Aggiunge insight da sessioni. Query per contesto rilevante.
- `Core/Context/KnowledgeEntry.swift`: Struct: type (decision/pattern/bug/file), content, source (sessionId), timestamp, relevanceScore.
- `Core/Context/ContextExtractor.swift`: (estensione) Analizza output/hook events per estrarre insight automaticamente. Filtra noise.
- `Core/Context/ContextInjector.swift`: Prepara prompt prefix con contesto rilevante per una nuova sessione. Rispetta token budget.
- `Core/Context/KnowledgeGraph.swift`: Persistenza in SQLite. Query per rilevanza. Decay temporale (insight vecchi perdono peso).
- Test: Test estrazione insight. Test query per rilevanza. Test injection in prompt.

---

### Sprint 19 — Performance & Testing

#### Step 19.1 — `performance-optimization`
**Agent**: `macos-core`
**Descrizione**: Sprint dedicato all'ottimizzazione delle performance per raggiungere i target: <200ms startup, <5ms input latency, <4ms frame render, <0.5% CPU idle, <10MB per sessione. Profiling con Instruments (Time Profiler, Metal System Trace, Allocations). Fix dei bottleneck trovati. Include: lazy initialization di moduli non necessari al startup, ottimizzazione del glyph atlas (texture compression), riduzione allocazioni nel rendering loop, ottimizzazione delle query SQLite (indices, prepared statements), memory pooling per buffer PTY.

**Deliverables**:
- `scripts/benchmark.sh`: Script che misura startup time, frame time, input latency, memory usage.
- Ottimizzazioni identificate e applicate (codice esistente migliorato).
- `docs/PERFORMANCE.md`: Documentazione dei target, misurazioni, e ottimizzazioni applicate.
- Test: Benchmark automatizzato che fallisce se un target non è raggiunto.

---

#### Step 19.2 — `comprehensive-testing`
**Agent**: `backend-core` + `frontend-ui`
**Descrizione**: Sprint dedicato al raggiungimento di code coverage >80% su Core/. Scrivere test mancanti per tutti i moduli Core. Integration test per i flow principali: lancio sessione → detection agente → state tracking → cost tracking → activity log. UI test per i flow critici: fleet overview navigation, diff review approve/reject, command palette search. Test di resilienza: cosa succede quando un processo muore inaspettatamente, quando un file config è corrotto, quando il disco è pieno. Test di performance: 50+ sessioni concurrent, 100K linee di scroll buffer.

**Deliverables**:
- Test unitari mancanti per ogni modulo Core/.
- Integration test per flow principali.
- Test di resilienza per scenari edge-case.
- Test di performance con molte sessioni.
- CI configuration (`scripts/ci-test.sh`) per eseguire tutti i test.

---

### Sprint 20 — Packaging & Release

#### Step 20.1 — `build-pipeline`
**Agent**: `macos-core`
**Descrizione**: Implementare il pipeline di build completo per distribuzione. Include: build con code signing (ad-hoc), Homebrew cask formula per `brew install --cask agentsboard`, Sparkle framework per auto-update con EdDSA verification. Il pipeline deve essere scriptabile e riproducibile. Include: versioning semantico, changelog generation da commit convenzionali, GitHub Release creation con asset upload.

**Deliverables**:
- `build.sh`: Build, sign, crea .app bundle.
- `Casks/agentsboard.rb`: Homebrew cask formula (distribuzione .zip).
- Sparkle integration per auto-update.
- `CHANGELOG.md`: Release notes per ogni versione.
- Test: Build pipeline gira senza errori. App si avvia dopo `brew install`.

---

#### Step 20.2 — `documentation-and-launch`
**Agent**: tutti
**Descrizione**: Sprint finale di preparazione al lancio. Completare: README con screenshots/GIF, guide utente (Getting Started, Configuration, Keyboard Shortcuts, Theme Creation, MCP Integration, CLI Usage), CONTRIBUTING.md per contributor, LICENSE (MIT), CHANGELOG.md. Preparare materiale marketing: video demo 2 minuti (script + recording con il nostro stesso recording engine), post per Hacker News (Show HN), thread Twitter/BlueSky, post Reddit. Creare Discord server con canali: #general, #bugs, #feature-requests, #themes, #providers.

**Deliverables**:
- README.md aggiornato con screenshots e GIF demo.
- `docs/GETTING_STARTED.md`: Guida da zero a prima sessione.
- `docs/CONFIGURATION.md`: Reference completa per YAML config.
- `docs/MCP_INTEGRATION.md`: Come usare AgentsBoard come MCP tool.
- `docs/CLI_REFERENCE.md`: Reference completa agentsctl.
- `docs/THEME_CREATION.md`: Come creare temi custom.
- `docs/CONTRIBUTING.md`: Guida per contributor.
- `CHANGELOG.md`: Changelog dalla v0.1.0.
- Script per video demo.
- Post templates per HN/Reddit/Twitter.

---

## Riepilogo Sprint

| Sprint | Fase | Focus | Steps |
|:------:|:----:|-------|-------|
| 1 | Fondamenta | Protocols, App skeleton, Config, Persistence | 1.1, 1.2, 1.3, 1.4 |
| 2 | Fondamenta | PTY manager, Metal renderer, Terminal integration | 2.1, 2.2, 2.3 |
| 3 | Fondamenta | Agent providers, State machine, Claude hooks | 3.1, 3.2, 3.3 |
| 4 | Fondamenta | Fleet aggregator, Project manager, Cost tracking | 4.1, 4.2, 4.3 |
| 5 | UI Core | Layout engine, Session cards, Sidebar | 5.1, 5.2, 5.3 |
| 6 | UI Core | Fleet overview, Activity log, Notifications | 6.1, 6.2, 6.3 |
| 7 | UI Core | Command palette, Keyboard system | 7.1, 7.2 |
| 8 | UI Core | Theme engine, Menu bar mode | 8.1, 8.2 |
| 9 | Code Review | Diff engine, Diff review UI, Pending changes flow | 9.1, 9.2, 9.3 |
| 10 | Code Review | File explorer, Code editor | 10.1, 10.2 |
| 11 | Code Review | Plan mode, Web preview, iOS simulator | 11.1, 11.2, 11.3 |
| 12 | Code Review | Mermaid renderer, Global search | 12.1, 12.2 |
| 13 | Orchestration | MCP server, CLI control | 13.1, 13.2 |
| 14 | Orchestration | Multi-session launcher, Session remix | 14.1, 14.2 |
| 15 | Orchestration | Recording engine, Playback viewer | 15.1, 15.2 |
| 16 | Orchestration | Task router, Verification chains | 16.1, 16.2 |
| 17 | Polish | Drag & drop | 17.1 |
| 18 | Polish | Cross-agent context | 18.1 |
| 19 | Polish | Performance, Comprehensive testing | 19.1, 19.2 |
| 20 | Polish | Build pipeline, Documentation & launch | 20.1, 20.2 |

| 21 | Testing | E2E sandboxed execution | 21.1, 21.2 |
| 22 | Performance | Metal viewport scissoring for 100+ sessions | 22.1 |
| 23 | Qt Desktop | Qt project scaffold, CoreFFI, Qt bindings, UI, terminal, packaging | 23.1–23.6 |

### Sprint 21 — E2E Test Sandbox

#### Step 21.1 — `e2e-macos-vm`
**Agent**: `devops`
**Description**: Set up a macOS VM (Parallels or UTM) for running XCUITest E2E tests without taking over the user's screen. Create `scripts/run-e2e-vm.sh` that boots the VM, copies the built .app, runs tests inside, and collects results.

#### Step 21.2 — `e2e-second-user`
**Agent**: `devops`
**Description**: Create a dedicated macOS user account for E2E testing. Create `scripts/run-e2e-user.sh` that uses `ssh testuser@localhost` to run XCUITest on a separate login session. The user can continue working on their primary session while tests run in the background.

### Sprint 22 — Metal Fleet Rendering

#### Step 22.1 — `metal-viewport-scissoring`
**Agent**: `macos-core`
**Description**: Bridge SwiftTerm's Terminal buffer (getCharData/getLine) into TerminalGridSnapshot, then render all sessions in a single MTKView using MetalRenderer's existing viewport scissoring. Zero NSView per session — pure GPU rendering for 100+ concurrent sessions. This is the migration path from SwiftTerm → Metal for the session grid.

### Sprint 23 — Qt Desktop App (Linux + Windows)

#### Step 23.1 — `qt-project-scaffold`
**Agent**: `qt-desktop`
**Description**: Create `qt/` directory with CMakeLists.txt, `src/main.cpp`, and a minimal QML window that displays "AgentsBoard" title. CMake must find Qt6 and link the Swift Core shared library. Verify builds on Linux with cmake + ninja.

#### Step 23.2 — `core-ffi-layer`
**Agent**: `backend-core`
**Description**: Create `Sources/CoreFFI/` module with `@_cdecl` Swift function exports and `include/agentsboard.h` C header. Expose lifecycle (create/destroy), fleet stats, session CRUD, state queries, cost stats, config loading, and callback registration. All pointers are opaque handles — no Swift types leak to C.

#### Step 23.3 — `qt-api-binding`
**Agent**: `qt-desktop`
**Description**: Create `CoreBridge.h/cpp` — C++ RAII wrapper classes over the C FFI. ABCore becomes a C++ class with proper constructor/destructor. Create `FleetModel` (QAbstractListModel) and `SessionModel` (QObject) that expose Core data to QML via Qt properties and roles.

#### Step 23.4 — `qt-fleet-session-ui`
**Agent**: `qt-desktop`
**Description**: QML views for FleetOverview (sorted cards grid), SessionList (sidebar), and SessionCard (state indicator, provider icon, cost, name). All data sourced from FleetModel/SessionModel via CoreBridge. Match the look and feel of the SwiftUI version.

#### Step 23.5 — `qt-terminal-widget`
**Agent**: `qt-desktop`
**Description**: Terminal rendering using QQuickPaintedItem or QQuickItem with custom OpenGL. PTY management via C FFI callbacks (ab_set_session_callback). VT parsing happens in Swift Core — Qt only renders the character grid and handles keyboard input.

#### Step 23.6 — `qt-packaging`
**Agent**: `devops`
**Description**: Package Qt app for distribution: `.deb` (Debian/Ubuntu), `.rpm` (Fedora), `.msi` (Windows), AppImage (Linux portable). Create `qt/packaging/` with platform-specific config. Dockerfile for reproducible Linux builds. GitHub Actions for CI.

**Totale: 23 sprint**
**Totale step: 52 skill/feature deliverables**
