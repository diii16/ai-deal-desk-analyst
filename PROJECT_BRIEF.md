# AI Deal Desk Analyst for Contact Center Resellers — Project Brief

Living document. Read this first in any new chat, then continue from section 9 "Build checklist".
Related files:
- `JUDGING_CRITERIA.md`
- `Intelligence at Work _ Technical Resources Guide.docx`
- `PROJECT_DETAILS.md`: analysis results, Q&A answers, decision log.
- `TALK_TRACK.md`: pitch.
- `skills/tco-modeling/SKILL.md`: agent method and rules.
- `skills/tco-benchmarking/SKILL.md`: Forrester and other evidence.
- `sql/`: all Snowflake code.
Last updated: 2026-10-23 (hackathon day). Solo team, business background, limited Snowflake experience.

## 0. Where to find things
- `README.md`: GitHub landing page.
- `PROJECT_DETAILS.md`: results, Q&A answers, decisions, plus the appendix moved from this brief (data model, TCO method, pricing appendix, Forrester reconciliation, design notes, full build log).
- `TALK_TRACK.md`: pitch, demo beats, Q&A prep, video outline.
- `skills/`: tco-intake (guided input, benchmark menus), tco-modeling (method), tco-benchmarking (evidence).
- `sql/`: 01 data, 02 calculator, 05 agent, 06 governance, 07 governance demo.

## 1. One-liner
A Claude-powered Cortex Agent that turns a reseller rep's messy discovery notes into a defensible,
source-cited total cost of ownership (TCO) recommendation and a buyer-ready deal brief, in minutes.
Everything is grounded in governed pricing data in Snowflake.

## 2. Problem fit (maps to judging criteria)
| Requirement | Our answer |
|---|---|
| Theme | **Internal**: from a deal question to a recommendation faster, with fewer handoffs |
| Persona | A **non-expert seller** (account exec / partner rep) at a **third-party reseller of Amazon Connect (and later Genesys Cloud CX)**. They have no TCO consulting experience but must talk TCO, compare vendors, and answer early-stage RFPs |
| Problem | Most sellers don't know how to price these solutions or compare vendors. A complex TCO takes a specialist consultant **40–80 hours**, and very few people can do it, so TCO conversations are bottlenecked or skipped early in the sales cycle |
| Measurable outcome | (1) Time to a first defensible TCO: **40–80 consultant hours → < 15 minutes** for a first-pass estimate. (2) **Who can do it:** from a few specialists → any seller. (3) **Trust:** 100% of numbers trace to a source URL, a price version, and a tagged assumption. The full complex TCO still gets a consultant review; we remove the early-stage bottleneck |
| Snowflake role | The governed source of truth: effective-dated price catalog, feature map, saved analyses, policies |
| Claude role | The intelligence: guides input gathering, extracts the demand profile, calls tools, reasons about trade-offs, writes the recommendation and talk track |
| Compounding | Claude cannot give trustworthy prices without Snowflake; Snowflake cannot interpret buyer needs or explain trade-offs without Claude |
| Not an anti-project | Not basic RAG, not dashboard-first, not a chatbot over docs. It is an agent that computes, decides, and writes back |

## 3. Hackathon scope (MVP slice) vs. vision
**Building today (demo scope):**
- Amazon Connect **Customer vs Customer Basic** only, North America, USD.
- Telephony: only the US rates already captured (DID $0.03/day, inbound $0.0022/min, outbound $0.0048/min), labeled as such.
- Small / medium / large default scenarios (section 7a).
- The AI guide explains each vendor option in plain language, so the seller can talk it through with the buyer.

**Vision (pitch only, not built):**
- Genesys Cloud CX (CX1 + Digital, CX2, CX3) and a cross-vendor apples-to-apples comparison.
- Full Global Telephony table, plus other regions and currencies (FX_RATES).
- Industry- and region-specific defaults and anonymized benchmarks from historical analyses (minimum group size of 5).
- Ingesting public analyst studies (e.g. Forrester TEI) via Cortex Search.
- PPT and Excel exports; exposing the agent to Claude Desktop and Teams via MCP.
- Private quoted/discount pricing per deal, alongside list price.

**Vision roadmap (for the pitch):**
1. **Self-maintaining price catalog.**
   - A weekly scheduled Snowflake Task fetches vendor pricing pages (via an external access integration).
   - Claude (`AI_COMPLETE`) extracts the prices into the catalog's structure and compares them with the current price version.
   - When anything changes, it creates a *draft* new price version and emails the catalog owner to approve it (human in the loop). Nothing is published automatically.
   - Saved analyses offer "re-price at today's rates".
   - Caveat: JavaScript-rendered tables (e.g. AWS Global Telephony) need a headless browser or the vendor's JSON feed.
2. **Multi-vendor comparison.**
   - Genesys Cloud CX first, then NICE CXone, Five9, Talkdesk, Zoom CX, Microsoft Dynamics 365 Contact Center.
   - Same demand profile and same outputs for every vendor (cost per agent per month, cost per contact, annual TCO), plus a cross-vendor capability-parity map.
3. **RFP accelerator.** Ingest RFP PDFs (`AI_PARSE_DOCUMENT`), auto-build the demand profile, and draft the pricing and TCO sections.
4. **Benchmarks network.** Anonymized benchmarks by industry, size, and region from saved analyses (with consent and a minimum group size), plus licensed analyst content (Cortex Knowledge Extensions).
5. **Everywhere sellers work.** The same governed agent in Teams/M365 Copilot, Claude Desktop (MCP), and CRM.
6. **Global.** Regions, currencies (FX_RATES), and local telephony.

## 4. User experience (demo flow, ~3 minutes)
1. The rep opens the **Deal Desk agent in CoWork** and pastes discovery notes (e.g. "80 agents, ~40k calls/mo, want chat, need QA evaluations").
2. **Guided intake:** the agent checks the notes against the minimum input list (section 5). It asks only for what is missing. If the rep doesn't know a value, it proposes a default from `SCENARIOS` / `BENCHMARK_DEFAULTS` with the source cited.
3. The agent calls the **TCO calculator tool** (a stored procedure) for Customer and Basic. All math is SQL over `PRICE_CATALOG`; Claude never invents prices.
4. The agent checks **capability parity** via `FEATURE_MAP` (e.g. Basic needs paid add-ons to match Customer).
5. It produces the **recommendation** with the reasons and the break-even point (e.g. "Customer wins above ~N agents because of evaluations and forecasting").
6. It **saves the analysis** (versioned, pinned to a price version) via the save tool.
7. It generates a **deal brief artifact**: a cost chart, a cost breakdown table, an assumptions table with USER/DEFAULT/BENCHMARK tags and sources, and a **talk track** for the rep.
8. **Wow moment:** "Actually they also need email." The agent re-runs and the recommendation shifts, with an explanation.
9. **Governance moment:** switch role. Rep B cannot see Rep A's analyses (row access policy), and a junior role sees discount fields masked.
10. Optional: show the agent trace (multi-step tool calls) and the eval results.

## 5. Guided input design
See `skills/tco-intake/SKILL.md` (minimum inputs, benchmark menus with star defaults, volume formulas).

## 6. Architecture (as built)
| Dimension | Component |
|---|---|
| Surface | **CoWork** (Snowflake Intelligence); no front end built |
| Context | `CX_TCO.CORE`: governed, effective-dated PRICE_CATALOG (version AWS-CONNECT-2026-10-23), FEATURE_MAP, SCENARIOS |
| Toolkit | Custom tools (stored procedures): `GET_DEFAULT_PROFILE`, `CALC_TCO` (deterministic, over the UDTF `CALC_TCO_LINES`), `SAVE_ANALYSIS`, `LIST_DEALS`; `data_to_chart` |
| Intelligence | Cortex Agent `DEAL_DESK_ANALYST` on claude-sonnet-4-5, with method from the three skills |
| Action | Governed write-back to `ANALYSES` (caller's rights) |
| Governance | Roles DEALDESK_REP / DEALDESK_MANAGER; row access `DEAL_OWNER_POLICY`; masking `DEAL_PRICE_MASK` |
| Cut for time | Semantic view / Cortex Analyst, evals, Streamlit, MCP |

## 8a. Time box (hard stops; cut scope, not the end buffer)
| Time | Block | Hard stop rule |
|---|---|---|
| 11:40–11:50 | Phase 0 setup checks | — |
| 11:50–12:30 | Phase 1 data load | — |
| 12:30–1:30 | Phases 2–3 calculator + save | If not working by 1:30, simplify to voice + chat only |
| 1:30–2:30 | Phase 5 agent in CoWork | If not working by 2:30, demo tools without the semantic view |
| 2:30–3:00 | Phase 6 governance | If late, show policies in SQL only |
| 3:00–3:30 | End-to-end test, evals if time | **3:30 = working MVP, feature freeze** |
| 3:30–4:00 | GitHub repo + README (guided step by step) | — |
| 4:00–4:20 | 1-minute video + demo rehearsal | — |
| 4:20–4:30 | Submit on Cerebral Valley | **Deadline 4:30** |

Status log: full log in PROJECT_DETAILS.md, section A6. Latest:
  - New tools `save_analysis` and `list_deals` run with caller's rights, so the policies follow the CoWork role.
  - Tested through the agent: the rep sees 3 deals with no quote columns; the manager sees 6 deals across 3 reps, with quotes and discounts.
  - **Next:** the user switches role in CoWork to show the difference live; then a 3:00 end-to-end test and a 3:30 freeze.
- 15:10: CoWork has no role switch in this account. The user's default role was restored to ATTENDEE_ROLE; the governance demo is `sql/07_governance_demo.sql` in a Snowsight worksheet.
- 15:15: The agent's 2,000-agent tipping-point table was mislabeled: Basic rows were shifted down one capability stack. The calculator itself was correct.
  - Real numbers: Customer $234.59 on every row; Basic $114.50 → $184.32 → $224.12 → $263.12 (tipping point at + forecasting + evaluations) → $298.34.
  - Agent v3.1 adds workflow 4b (one calc_tco call per row, exact labels, sanity checks) and the 2,000-agent pattern.


## 9. Build checklist (follow in order; tick as we go)
**Phase 0 — Setup checks**
- [x] Confirm the role, warehouse, and Claude model availability (cross-region inference), and that CoWork is accessible.

**Phase 1 — Data**
- [x] Create `CX_TCO.CORE`; load PRICE_CATALOG, FEATURE_MAP, SCENARIOS, BENCHMARK_DEFAULTS from section 10.

**Phase 2 — Calculator**
- [x] `CALC_TCO(profile JSON)` stored procedure, returning a cost breakdown for Customer vs Basic.
- [x] Hand-check one scenario against the AWS worked example.

**Phase 3 — Persistence**
- [x] `SAVE_ANALYSIS` procedure plus a single ANALYSES table (INPUTS / RESULTS tables cut for time).

**Phase 4 — Semantic view**
- [ ] Create a semantic view over the pricing and features.

**Phase 5 — Agent**
- [x] Create the Cortex Agent with instructions (guided intake rules, citation rules, talk-track format).
- [x] Tools: CALC_TCO, GET_DEFAULT_PROFILE. (Analyst and SAVE_ANALYSIS deferred; code execution not added.)

**Phase 6 — Governance**
- [x] Create roles, the row access policy, and the masking policy; test with a role switch (SQL + agent verified; CoWork UI pending).

**Phase 7 — Quality**
- [ ] 3–5 agent evaluations (S/M/L, a missing-input case, the email flip case).
- [ ] Review a trace.

**Phase 8 — Deliverables**
- [x] **(Done 15:25)** slim PROJECT_BRIEF.md to 1–2 pages. Keep §1–4, a short §6, §8a with the last few log entries, §9, and a "Where to find things" index. Move §7/7a, §8, §10/10b, §11, §12 and the full status log to PROJECT_DETAILS.md. Replace §5 with a pointer to `skills/tco-intake/SKILL.md`. No content lost.
- [ ] Public GitHub repo (SQL, agent spec, README listing "built today", no secrets).
- [ ] Demo script and a 1-minute video.
- [ ] Vision slide.

**Stretch (only if ahead)**
- [ ] Streamlit front end.
- [ ] MCP exposure to Claude Desktop.
- [ ] Web search for benchmarks.
- [ ] PPT export.

**Fallback if behind:** skip Phases 4 and 7; demo the agent with only the CALC_TCO and SAVE tools.

