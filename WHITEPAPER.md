# Multi-Agent System Architecture: Design Principles

> **AJD Whitepaper** — Abstracted from a production multi-agent system (11 bots, 9 profiles) into reusable design principles. No private data included.

---

## 1. The Problem: Why Split Agents at All?

When a single agent tries to do everything, you hit three walls:

| Wall | Symptom | Root Cause |
|------|---------|------------|
| **Context explosion** | Prompt grows to 70k+ tokens; tool calls time out | One agent holds all domain knowledge |
| **Failure blast radius** | One broken tool crashes the whole session | No fault isolation |
| **Skill conflict** | Calendar skill fights stock skill for `date` parsing | Shared namespace, no ownership |

**Splitting** gives each agent a *bounded context*: one job, one token budget, one failure domain.

---

## 2. The Splitting Axis: What Defines a Boundary?

Don't split by "topic" (news vs. stocks). Split by **operational contract**:

| Dimension | Question | Example |
|-----------|----------|---------|
| **Trigger** | What wakes it? | Cron (time), Webhook (event), Chat (human) |
| **Output** | What does it produce? | File, API call, Message, DB write |
| **SLA** | How fast must it reply? | <3s (chat), <5min (batch), <24h (report) |
| **Secrets** | Which credentials does it need? | LINE token, GitHub PAT, YouTube OAuth |
| **Failure mode** | What happens when it dies? | Silent (cron), Alert (webhook), Retry (chat) |

**Rule**: If two workflows differ on ≥2 dimensions, they belong in different agents.

---

## 3. Profile = Deployment Unit

A *profile* is the smallest deployable unit: one process, one port, one config directory.

```
~/.hermes/profiles/
├── default/        # chat + daily driver (port 8643)
├── ops/            # infra, deploy, monitoring (port 8644)
├── news/           # news pipeline (port 8643, no_agent)
├── stock/          # stock pipeline (port 8643, no_agent)
├── gtk/            # game bot (port 8645)
├── kktube/         # YouTube upload (port 8646)
├── music/          # music showcase (port 8647)
├── myp/            # personal assistant (port 8648)
└── ajd/            # this dashboard (port 5080)
```

**Each profile owns:**
- Its own `memories/config` (env vars, secrets)
- Its own `cron/` (scheduled jobs)
- Its own `skills/` (tools it can call)
- Its own `plugins/` (UI extensions)

**Profiles do NOT share:**
- Token budgets (each gets its own model pool)
- Conversation history
- File descriptors

---

## 4. Inter-Profile Communication: Explicit, Not Implicit

No shared memory. No global state. Communication happens through **durable, inspectable channels**:

| Channel | Use Case | Latency | Durability |
|---------|----------|---------|------------|
| **File system** | Large artifacts (videos, reports) | ms | Days |
| **HTTP webhook** | Event triggers (upload done, build failed) | <100ms | Retry queue |
| **Message queue (Telegram/LINE)** | Human-visible notifications | <1s | Forever |
| **Shared DB (SQLite)** | Structured queries across profiles | <10ms | Forever |
| **Heartbeat API (AJD)** | "I finished" signals | <50ms | 400 entries |

**Anti-pattern**: Profile A imports Profile B's Python module.
**Pattern**: Profile A POSTs to Profile B's webhook / writes to shared DB / drops file in agreed directory.

---

## 5. Model Routing: Primary + Fallback Chain

Each profile declares its own model pool. No global "smart router" — the profile *knows* what it needs.

```yaml
# ~/.hermes/profiles/news/memories/config
model_pool:
  primary:
    provider: nvidia
    model: google/gemma-4-31b-it
  fallback:
    - provider: openrouter
      model: free-tier-1
    - provider: openrouter
      model: free-tier-2
    - provider: ollama
      model: deepseek-r1:14b
```

**Principles:**
- **Primary = cheapest that works** for this profile's typical prompt size
- **Fallbacks = different providers** (not different models on same provider)
- **Local last** — only for "keep the lights on" when cloud is down
- **No cross-profile fallback** — if news profile is down, stock profile doesn't steal its model

---

## 6. Cron vs. Agent: Who Schedules What?

| Scheduler | Owns | Trigger | Heartbeat |
|-----------|------|---------|-----------|
| **System cron/launchd/systemd** | Machine-level: backups, cert renewals, log rotation | Time | Optional |
| **Hermes cron (per profile)** | Agent-level: daily report, fetch feed, publish video | Time + agent context | **Required** |
| **Webhook** | Event-driven: PR merged, file uploaded, payment received | HTTP POST | N/A |
| **Human chat** | Ad-hoc: "run the report now", "debug this" | Message | N/A |

**Rule**: If the job needs *agent context* (skills, memories, model), it runs in Hermes cron. If it's pure infrastructure, it runs in system cron. Both can POST to AJD's `/api/heartbeat`.

---

## 7. Secrets: One Profile, One Secret Store

```
~/.hermes/profiles/<name>/memories/
├── config          # env vars (AJD_URL, PORT, etc.)
├── line_token.txt  # only LINE bot profile reads this
├── yt_token.json   # only kktube profile reads this
├── gh_pat.txt      # only ops profile reads this
└── notion_key.txt  # only research profile reads this
```

**No secret is ever** in a shared location, in git, or in a docker image. Each profile's `memories/` is `chmod 700`.

---

## 8. Observability: The Dashboard Is Not the System

AJD (this dashboard) is a **read-only observer**. It:
- Scrapes snapshots (file counts, git commits, dir sizes)
- Receives heartbeats (POST `/api/heartbeat`)
- Checks ports / HTTP / Docker
- **Never** triggers jobs, **never** modifies source projects

**Why this matters**: If AJD dies, your agents keep running. If your agents die, AJD shows you *exactly which one* and *when it last reported*.

---

## 9. Adding a New Agent: Checklist

When you need a new capability, ask:

1. **Trigger differs?** → New profile
2. **Secrets differ?** → New profile
3. **SLA differs?** → New profile
4. **Failure mode differs?** → New profile
5. **Only prompt differs?** → Same profile, new skill

If ≥2 "yes" → new profile. Create `~/.hermes/profiles/<name>/`, add its config, cron, skills. Register in AJD's `projects.json`. Done.

---

## 10. What This Is Not

- **Not a framework** — no base class, no SDK, no required libraries
- **Not a message bus** — profiles don't auto-discover each other
- **Not a service mesh** — no sidecars, no mTLS, no circuit breakers
- **Not opinionated on language** — Python, Go, Bash, Node all work

It *is* a set of **boundaries that have survived production use** across 11 bots, 2 years, 0 cross-profile outages.

---

## 11. Applying This to Your System

| Your Situation | Start Here |
|----------------|------------|
| One agent doing 5+ things | List its triggers/outputs/SLAs → split on ≥2 differences |
| Agents stepping on each other's secrets | Give each its own `memories/` directory |
| "Is it still running?" is a daily question | Add heartbeat POST to each cron job; point AJD at them |
| New requirement arrives | Apply the checklist in §9 before writing code |

---

## License

MIT — same as AJD. Use, adapt, disagree with any part.

---

*Abstracted from a real system running since 2024. The concrete implementation (11 bots, specific tokens, exact paths) is private. The principles are not.*