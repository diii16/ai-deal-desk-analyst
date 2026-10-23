# Project Details — Analysis Results & Decisions

Reference record of what we found and decided while building. The plan and status live in `PROJECT_BRIEF.md`; the pitch lives in `TALK_TRACK.md`; agent rules and evidence live in `skills/`.

## 1. Calculator validation
- **AWS pricing example 1** (75 agents; 100k voice min, 50k chat messages, 20k SMS):
  - Our `CALC_TCO_LINES` = **$4,800.90/month**, an exact match to AWS.
- **SMALL scenario (250 agents):** hand-checked line by line; matches.
- **Price version:** `AWS-CONNECT-2026-10-23`.
- **Sources:** AWS overview, pricing, and pricing appendix pages, all fetched 2026-10-23.

## 2. Default S/M/L results
Buyer needs analytics, agent assist, forecasting/scheduling, and evaluations.

| Size | Customer annual | Basic (with matching add-ons) annual | Customer per agent per month | Basic per agent per month | Customer saves |
|---|---|---|---|---|---|
| Small (250) | $704k | $805k | $234.59 | $268.23 | ~13% |
| Medium (800) | $2.25M | $2.58M | $234.59 | $268.23 | ~13% |
| Large (2,000) | $5.63M | $6.31M | $234.59 | $263.12 | ~11% |

## 3. Capability scenarios (250 agents, per agent per month)
| Buyer needs | Customer | Basic | Cheaper | Annual difference |
|---|---|---|---|---|
| 1. Voice only, no AI | $262.52 | $132.69 | Basic | Basic saves $389k |
| 2. Voice + chat + email, no AI | $234.59 | $114.50 | Basic | Basic saves $360k |
| 3. Voice only + analytics | $262.52 | $230.06 | Basic | Basic saves $97k |
| 4. Voice only + analytics + agent assist | $262.52 | $275.22 | Customer | Customer saves $38k |
| 5. Omni + analytics + agent assist | $234.59 | $229.23 | ~even | Basic saves $16k |
| 6. Omni + analytics + assist + WFM + QA | $234.59 | $268.23 | Customer | Customer saves $101k |
| 7. Omni + everything | $234.59 | $303.45 | Customer | Customer saves $207k |

**Size sensitivity (voice + analytics + assist):**
- 50 agents: Customer $262.52 vs Basic $275.22.
- 2,000 agents: Customer $262.52 vs Basic $265.24.

## 4. Answers to the project owner's questions (13:15)
**"If a customer is small and uses only one or two channels, is Basic cheaper?"**
- Yes, *if they don't need the AI capabilities*. The driver is capabilities, not size.
- Both options are usage-based, so cost per agent is nearly flat from 50 to 2,000 agents.
- The only size effect is Basic's voice analytics discount above 5M minutes per month.

**"Can the seller type any agent number?"**
- Yes. `GET_DEFAULT_PROFILE(agents, 'VOICE_ONLY' | 'OMNI')` builds DEFAULT volumes for any count.
- 250 / 800 / 2,000 are only quick-start presets.

**"Can the agent say which option is cheaper?"**
- Yes. `CALC_TCO` returns both options side by side.
- The agent recommends the cheaper one *with capability parity* and lists what Basic can't provide.

**"At what point should a buyer switch from Basic to Customer?"**
- Basic is right for buyers "not ready for AI", or using analytics only.
- Plan the switch when the buyer adds:
  - **analytics + real-time agent assist** on a voice-heavy center, or
  - **any per-agent add-on** (forecasting/scheduling $27, evaluations $12).
- **Rule of thumb:**
  - Customer's premium over Basic's channel rates is ~$120–130 per agent per month at default volumes.
  - Once the Basic add-on bill passes that, Customer is cheaper *and* unlocks the features Basic lacks.
- The agent proves this live by re-running `CALC_TCO` with one capability toggled at a time.

## 5. Forrester TEI reconciliation
**Forrester composite (Year 1):**
- ~$269 per agent per month for usage only.
- ~$282 risk-adjusted.
- **~$303** including migration and ongoing management.

**Our calculator on the same inputs** (2,000 agents, 8.8-min AHT, 75% voice, 10 messages per chat):
- **$227** per agent per month for Customer.

**Gap explained:**
- Telephony: we use the $0.0022/min US DID inbound rate; Forrester uses a $0.0106/min blended rate.
- Telephony is the same for both options, so it does not change the recommendation.

**Stretch TODO:** make blended telephony $/min a seller input, with the Forrester value as a cited option.

## 6. Re-check: "voice-only, 250 agents, full AI" (14:15)
The agent's answer was checked line by line and is **correct**:
- Customer $65,629/month vs Basic $88,715/month; Customer saves $23,086/month ($277k/yr, 26%).
- Basic's voice rate is half of Customer's ($29.2k vs $61.7k platform cost), but the full AI add-on bill is $55.5k (analytics $24.3k, agent assist $11.3k, screen recording $8.5k, self-service $1.7k, WFM $6.75k, QA $3.0k). That exceeds the $32.5k platform gap.
- Basic wins voice-only at 250 agents when the buyer needs **no AI** ($132.69 vs $262.52 per agent per month) or **analytics only** ($230.06 vs $262.52).

**Model limitation (roadmap):**
- Add-ons are assumed to cover **100% of calls**.
- Real Basic buyers often record or analyze only a share (AWS's own screen-recording example uses 30%).
- Even with screen recording removed, Customer still wins full AI ($80.2k vs $65.6k), but partial coverage narrows the gap.
- **TODO:** a coverage % per add-on.

## 7. Key decisions log
| Time | Decision |
|---|---|
| 11:30 | Reframe from "TCO calculator" to "AI Deal Desk Analyst" (avoids the dashboard anti-project; gives Claude a clear role) |
| 11:35 | Surface: CoWork (no front end to build); Streamlit is a stretch |
| 11:35 | Database `CX_TCO.CORE`; S/M/L = 250 / 800 / 2,000 agents |
| 13:20 | Forrester and other benchmarks live in the agent skill `tco-benchmarking`, not in the database |
| 13:25 | Two skills: `tco-modeling` (method, rules, output format) and `tco-benchmarking` (evidence). Benchmarks change independently of the method; future vendors get their own benchmark skills |
| 13:25 | Build the agent before Phase 3 (save analyses); add saving as an agent tool if time allows |

---
# Appendix (moved from PROJECT_BRIEF.md at 15:25, unchanged)

## 7. Snowflake data model (database `CX_TCO`, schema `CORE`; not yet created)
- `PRICE_CATALOG`
  - Columns: vendor, product/tier, component, channel, unit, price, tier break points, region, currency, `effective_from`/`effective_to`, `price_version`, source_url, loaded_at.
- `FEATURE_MAP`: capability, vendor, tier, status (included / add-on / not available), add-on price reference.
- `SCENARIOS`: S/M/L demand profiles (defaults).
- `BENCHMARK_DEFAULTS`: metric, value, source_name, source_url (public only).
- `ANALYSES`: id, owner (CURRENT_USER), deal/buyer name, status, created/updated, `cloned_from_id`, `price_version`.
- `ANALYSIS_INPUTS`: versioned snapshot of inputs with their source tags.
- `ANALYSIS_RESULTS`: cost by layer and option, cost per agent/month, cost per contact, annual TCO, recommendation text.
- `DEAL_DISCOUNTS` (demo of a masked column): private quoted price per analysis.
- Policies:
  - a row access policy on ANALYSES* (owner = current user, or a manager role sees all);
  - a masking policy on the discount column.
- Roles: `DEALDESK_REP`, `DEALDESK_MANAGER` (demo users can switch between them).

### 7a. Default scenarios (North America, USD) — agreed 2026-10-23
**Size bands and default agent counts:**

| Size | Band | Default agents |
|---|---|---|
| Small | < 500 agents | 250 |
| Medium | 500–999 agents | 800 |
| Large | 1,000+ agents | 2,000 |

**Per-agent monthly defaults.** These are the same for every size, so totals scale with agent count. All are tagged `DEFAULT` (our working assumptions, editable, not a cited benchmark):

| Driver | Default | Derivation |
|---|---|---|
| Paid hours | 168 h | 8 h × 21 days |
| Shrinkage | 30% | breaks, training, absence |
| Occupancy | 80% | |
| Handle minutes / agent | ~5,650 | 168 × 0.7 × 0.8 × 60 |
| Channel mix of handle time | voice 70% / chat 20% / email 10% | |
| Voice AHT | 6 min | ~660 calls, ~3,950 agent voice min |
| IVR / queue time per call | 1 min | ~660 extra billable voice min |
| Inbound share of calls | 90% (10% outbound) | |
| Chat | 10 min per chat, concurrency 2, 20 messages per chat | ~226 chats, ~4,500 messages |
| Email | 8 min AHT | ~70 emails |
| Phone numbers | 1 DID per 10 agents | |
| Capabilities assumed needed | analytics, agent assist, forecasting/scheduling, evaluations | |

**Future work:** vary the mix by size and industry, and replace defaults with cited benchmarks (`BENCHMARK_DEFAULTS`).

## 8. TCO methodology (MVP)
**Outputs:** monthly cost, annual TCO, cost per agent per month, and cost per contact for each option.

**Layers included today:** platform usage, telephony (US rates only), AI/analytics add-ons, per-agent add-ons (Basic: forecasting $27, evaluations $12).

**Layers excluded today (pitch as vision):** implementation, migration, admin/training, and agent labor (shown as a note: often 60–70% of contact center cost).

**Capability parity:** Basic's cost includes the add-ons needed to match the capabilities the buyer requires. Capabilities unavailable in Basic are flagged.

**Transparency:** every assumption is editable and has a source.

## 10. Appendix — Amazon Connect pricing captured
Source: https://aws.amazon.com/products/connect/customer/pricing/appendix/ (fetched 2026-10-23).

### Connect Customer channel rates
All AI features (analytics, self-service incl. Lex, forecasting, evaluations, agent assist, screen recording, etc.) are included in these rates.

| Channel | Price |
|---|---|
| Voice | $0.038 / min (voice service; telephony billed separately) |
| Chat | $0.010 / message |
| Messaging (SMS, Apple Messages, WhatsApp) | $0.014 / message (+ SMS delivery fees) |
| Email | $0.080 / email |

Voice communication charges (on top of the voice service rate):
- In-app / web audio: $0.010 / min.
- Video: $0.015 / min / participant.
- Screen share: $0.015 / min.

Voice billing:
- Per second, 10-second minimum.
- External voice: $0.032 / min + $100 per connector per day.
- Test & simulate (voice): $0.038 / min + $0.010 / min web audio.

### Connect Customer additional features
| Feature | Price |
|---|---|
| Outbound campaigns | $0.045 / min (instead of $0.038) |
| Tasks | $0.070 / task |
| Step-by-step guides | $0.010 / message |
| Live Sync | $0.01 / min on top of the channel rate. Billed per second, 1-minute minimum. Free trial until 2026-11-30 |
| Cases | $0.12 / case created |
| Customer Profiles (Connect data only) | $0.00 |
| Customer Profiles (imported data) | $0.005 / profile utilized daily. +$0.005 per extra 100 objects. Capped at 30% of stored profiles per day |
| 3P AI agent collaboration (A2A), text | $0.001 / message |
| 3P AI agent collaboration (A2A), voice | $0.01 / min |
| AgentCore Gateway / Bedrock Knowledge Bases | Billed separately by AWS |

### Customer Basic (a la carte) rates
| Item | Voice | Chat | Messaging | Email |
|---|---|---|---|---|
| Channel usage | $0.018/min | $0.004/msg | $0.010/msg | $0.050/email |
| Conversational analytics + summaries | $0.015/min (first 5M min), then $0.0125/min | $0.0015/msg | $0.0015/msg | n/a |
| End-customer self-service | $0.008/min + Lex | $0.0015/msg + Lex | $0.0015/msg + Lex | n/a |
| Real-time agent assist | $0.008/min | $0.0015/msg | $0.0015/msg | $0.020/inbound email |
| Screen recording | $0.006/min | n/a | n/a | n/a |
| Test & simulate | $0.018/min + web audio | $0.004/msg | n/a | n/a |

Per-agent features (Basic):
- Forecasting & scheduling: $27 / agent / month.
- Performance evaluations: $12 / agent / month.

Other Basic rates:
- External voice: $0.012 / min + $100 per connector per day.
- Polly generative TTS: charged separately.

Not available in Basic (examples): email analytics, customer-first callbacks, estimated wait time, flow designer analytics, custom metrics, self-service evaluations, Nova Sonic, AI case summaries, 3P STT/TTS.

### Telephony (US, us-west-2, from the page's worked examples)
- US DID number: $0.03 / day.
- Inbound DID: $0.0022 / min.
- Outbound to a US destination: $0.0048 / min.
- GAP: the full Global Telephony table is rendered by JavaScript. Deferred to the vision.

### Free tier and trials (ignored in TCO, noted in the deal brief)
- Customer Profiles: 1,000 profiles per month for 12 months.
- Chat analytics: 500 messages per month for 12 months.
- Voice analytics: 100,000 minutes per month for the first 2 months.
- Evaluations: 30-day trial.
- Forecasting: 90-day trial.

### Re-verification 2026-10-23 ~11:55 (overview, pricing, appendix pages)
All prices above match the live pages. New modeling rules found:
1. **No mixing.** Connect Customer charges apply to *all* channel usage in an account. A buyer is either on Customer or on Basic per instance, never a blend.
2. **Voice service minutes include IVR, queue, and agent time** (the full active call). This confirms the 1 min IVR/queue default.
3. **Billing minimums.**
   - Voice service: per second, 10-second minimum.
   - Telephony inbound/outbound: per second, **60-second minimum**.
   - Ignore at our level of detail; note it as a caveat.
4. **Customer chat counts every message:** customer, human agent, AI agent, and manager-assist prompts/responses, all at $0.010. The chat messages-per-conversation default should include bot messages.
5. **Basic voice:**
   - Inbound and outbound voice usage are both $0.018/min.
   - Outbound campaigns on Customer are $0.045/min.
6. **Basic per-agent add-ons:**
   - Forecasting & scheduling $27 per agent per month.
   - Evaluations $12 *per agent evaluated* per month; on Basic, evaluations only cover human-handled contacts.
7. **Basic screen recording** ($0.006/min) covers agent-connected time and after-contact work only, not IVR. Use agent handle minutes, not total voice minutes.
8. **Customer coverage gaps by channel:** forecasting/scheduling and screen recording are not offered for email even on Customer; self-service is not offered for email.
9. **Basic is positioned by AWS as legacy** ("Some customers might still be on Customer Basic"; "Not ready for AI?"). This is useful talk-track context.
10. **Cases:**
    - Both: $0.12 per case.
    - Customer includes AI case summaries; Basic does not.

**Still missing:**
- Global Telephony table (JS-rendered; empty in fetch).
- Basic Tasks / Guides / Customer Profiles tab prices (JS tabs).
- MVP keeps tasks/cases out of scope.

**Public sources for talk track / BENCHMARK_DEFAULTS:**
- **Forrester TEI of Amazon Connect (PDF):** https://d1.awsstatic.com/onedam/marketing-channels/website/aws/en_US/product-categories/contact-center/approved/images/Forrester_TEI_The_Total_Economic_Impact_Of_Amazon_Connect.pdf
  - The headline numbers are JS-rendered; read them from the PDF if needed.
- **Customer quotes (pricing page):**
  - Flybuys: "50% reduction in our platform costs".
  - Cochlear: the unlimited AI price replaces third-party workforce management (WFM) and quality management (QM) tools.
- **IDC MarketScape:** Worldwide Agentic CCaaS Platforms 2026 (overview page).

## 10b. Forrester TEI reconciliation and capability scenarios (2026-10-23 ~13:15)

### Forrester TEI (Feb 2026, commissioned by AWS)
**Composite organization:**
- 2,000 agents, 200 supervisors.
- 20M contacts per year; 75% calls, 25% chat.
- AHT 10 min with legacy systems, 8.8 min with Connect in Year 1.
- 10 messages per chat; 30% growth per year.

**Headline results:**
- ROI 342%; NPV $78.7M; benefits PV $101.7M; costs PV $23.0M; payback under 6 months.

**Usage cost (Year 1, table F):**
- 119.68M call minutes per year × ($0.038 Connect + **$0.0106 blended telephony**), plus 64M chat messages × $0.010.
- = $6.46M, or $6.78M risk-adjusted (+5%).

**Derived per-agent cost, Year 1:**

| Basis | Per agent per month |
|---|---|
| Usage only | $6.456M / 12 / 2,000 = **$269** |
| Risk-adjusted usage | $6.779M → **$282** |
| Total Year 1 cost incl. migration + ongoing management | $7.281M → **$303** (the "$300+" figure) |

**Our calculator on the same inputs:**
- Customer = $227 per agent per month.
- The gap is almost entirely **telephony**: we use the $0.0022/min US DID inbound rate, while Forrester uses a $0.0106/min blended rate (likely toll-free plus outbound mix).
- Telephony is identical for Customer and Basic, so it changes the absolute TCO but **not the recommendation**.
- **TODO (stretch):** add a "blended telephony $/min" input, defaulting to the DID rates, with the Forrester $0.0106 option cited.

**Other citable benchmarks from the TEI:**
- AHT down up to 12%.
- Containment up 10% per year.
- Post-contact summaries save 60 s per call.
- QA coverage goes from 1–3% to 100%.
- WFM: 5% fewer agents; supervisor span 10 → 12.
- Legacy license $180 per user per month + 30% overhead.
- Agent loaded cost $45,760 per year ($22/h).
- Some interviewees spent *more* on Connect but got much more functionality.

### Capability scenarios (250 agents; per agent per month, Customer vs Basic)
| Scenario | Customer | Basic | Cheaper |
|---|---|---|---|
| 1 Voice only, no AI | $262.52 | $132.69 | **Basic** (-$389k/yr) |
| 2 Voice + chat + email, no AI | $234.59 | $114.50 | **Basic** (-$360k/yr) |
| 3 Voice only + analytics | $262.52 | $230.06 | **Basic** (-$97k/yr) |
| 4 Voice only + analytics + agent assist | $262.52 | $275.22 | **Customer** (+$38k/yr) |
| 5 Omni + analytics + agent assist | $234.59 | $229.23 | ~even (Basic -$16k/yr) |
| 6 Omni + analytics + assist + WFM + QA (default) | $234.59 | $268.23 | **Customer** (+$101k/yr) |
| 7 Omni + everything (screen rec, self-service) | $234.59 | $303.45 | **Customer** (+$207k/yr) |

**Key insights (talk track):**
1. **Capabilities decide, not size.** Both options are usage-based, so per-agent cost is nearly flat with size: 50 vs 2,000 agents gives Customer $262.52 vs $262.52 and Basic $275.22 vs $265.24. The only size effect is Basic's analytics tier above 5M voice minutes per month.
2. **Switch point.** Basic wins while a buyer needs no AI, or analytics only. Once they add **analytics + agent assist** (voice-heavy), or any **WFM/QA** per-agent add-on, Customer becomes cheaper and also unlocks the features Basic lacks (email analytics, custom metrics, callbacks, estimated wait time, etc.).
3. **Rule of thumb for sellers:**
   - Start on Basic if the buyer is "not ready for AI".
   - Plan the move to Customer when the buyer's Basic AI add-on bill (analytics + assist + $27 WFM + $12 QA per agent) exceeds Customer's premium over Basic channel rates. At default volumes that premium is about $120–130 per agent per month.

**New tool:** `GET_DEFAULT_PROFILE(agents, 'VOICE_ONLY'|'OMNI')` builds DEFAULT volumes for any agent count, so the agent is not limited to 250/800/2,000.

**Decision (user, 13:20):**
- Forrester TEI benchmarks, methodology rules, guided-intake rules, switch-point patterns, and the output format live in **two agent skills**:
  - `skills/tco-modeling/SKILL.md`: method, rules, output format.
  - `skills/tco-benchmarking/SKILL.md`: Forrester, AWS quotes, scenario results.
  - They live there, not in the database.
- `BENCHMARK_DEFAULTS` keeps its original 8 rows.
- Plan: upload the skill to a stage and attach it to the Cortex Agent; if skills aren't supported, paste it into the agent instructions.

## 11. Design considerations (carry forward)
**Neutrality:**
- Transparent methodology.
- Parity notes next to prices.
- Disclose that the reseller sells both vendors.

**Privacy:**
- Buyer data is customer data.
- Each rep sees only their own analyses (row access policy).
- Benchmarks require consent, anonymization, and a minimum group size.

**Pricing:**
- List price (public) stays separate from quoted/discount price (private, masked).
- Check the AWS and Genesys partner terms before publishing benchmarks.

**Replicability:**
- Each analysis is pinned to a `price_version`.
- Offer "re-price at today's rates".

## 12. Open decisions
- [x] Database name: `CX_TCO` (confirmed).
- [x] Primary surface: CoWork (confirmed; Streamlit is a stretch).
- [x] Baseline: 40–80 consultant hours per complex TCO; few people are capable (confirmed by the user's sales experience).
- [x] S/M/L: 250 / 800 / 2,000 agents (confirmed); per-agent defaults in section 7a (user to review).

## A6. Full build status log
- 11:37: planning done; starting Phase 0.
- 11:50: Phase 0 done.
  - Role ATTENDEE_ROLE (has CREATE DATABASE, CREATE ROLE, MANAGE GRANTS, CORTEX_USER); warehouse DEFAULT_WH; region AWS_US_WEST_2.
  - Cross-region inference = ANY_REGION. AI_COMPLETE tested OK with claude-sonnet-4-5 and claude-opus-4-5.
  - Cortex Agents work (a sample agent STOWEAWAY_GROWTH_ANALYST exists; use it as a CoWork reference). `CX_TCO` does not exist yet.
  - ACCOUNTADMIN is also available if needed.
- 12:08: Phase 1 done.
  - `CX_TCO.CORE` created. Rows loaded: PRICE_CATALOG 35, FEATURE_MAP 32, SCENARIOS 3, BENCHMARK_DEFAULTS 8.
  - Price version `AWS-CONNECT-2026-10-23`. Script: `sql/01_setup_and_load.sql`.
  - Talk track saved in `TALK_TRACK.md`.
- 12:40: Phase 2 done (`sql/02_calculator.sql`).
  - Objects: `V_SCENARIO_VOLUMES` (S/M/L volumes), `CALC_TCO_LINES` (UDTF cost lines), `CALC_TCO` (agent tool proc, returns JSON).
  - **Validated:** AWS example 1 reproduces $4,800.90 exactly; SMALL was also hand-checked line by line.
  - Results with default needs (analytics, agent assist, forecasting, evaluations):
    - Customer $234.59 per agent per month at every size.
    - Basic $268.23 (S/M) and $263.12 (L) per agent per month.
    - **Customer is ~12–13% cheaper** at every size.
    - Annual TCO: SMALL $704k vs $805k; MEDIUM $2.25M vs $2.58M; LARGE $5.63M vs $6.31M.
    - Story: Basic's channel rates are less than half of Customer's, but the add-ons needed for parity (~$38k/mo at SMALL) flip the result. With no AI needs, Basic would be ~50% cheaper.
  - Known gotchas:
    - The UDTF needs FLOAT-cast literals when called directly.
    - A lateral join of the UDTF over a view is unsupported; call the proc per scenario.
- 13:50: Phase 5 done (agent created and tested).
  - Agent `CX_TCO.CORE.DEAL_DESK_ANALYST` (claude-sonnet-4-5); spec in `sql/05_agent.sql`.
  - Tools: `get_default_profile` and `calc_tco` (procedures). Instructions embed both skills.
  - Test (300 agents, omni + analytics + assist + WFM + QA): 3 tool calls; recommends Customer, saving $121,094/yr (12.5%). Switch point: without WFM + QA, Basic is $5.36/agent/month cheaper. Full deal-brief format.
  - Deferred: semantic view (Phase 4) and SAVE_ANALYSIS (Phase 3).
  - **Next:** verify in CoWork UI, then governance (Phase 6).
- 14:00: user confirmed the agent is visible and working in CoWork (ai.snowflake.com).
- 14:10: Agent v2 live.
  - Sample prompts (incl. "What can you do?" and the user's 250- and 2,000-agent prompts).
  - Benchmark menus for unknown inputs; "How we calculated this" section (formulas, quantity × price, source URLs).
  - `data_to_chart` tool added.
  - New skill `skills/tco-intake/SKILL.md` (guided operational data input and benchmark menus).
  - Test (2,000 agents, omni): tools get_default_profile → calc_tco → data_to_chart → calc_tco; chart rendered; recommends Customer, saving ~$685k/yr (10.8%).
  - Known nit: the headline saving ($684,674) and the table ($684,655) differ by rounding. Acceptable; mention it if asked.
- 14:45: Phase 6 governance done (`sql/06_governance.sql`); agent v3 live via ALTER AGENT (grants kept).
  - ANALYSES table, seeded with 6 synthetic deals from 3 reps; roles DEALDESK_REP (seller Jordan Lee) and DEALDESK_MANAGER, both granted to USER.
  - Row access DEAL_OWNER_POLICY: a rep sees only their own deals. Masking DEAL_PRICE_MASK: quoted price and discount hidden from reps.
  - New tools `save_analysis` and `list_deals` run with caller's rights, so the policies follow the CoWork role.
  - Tested through the agent: the rep sees 3 deals with no quote columns; the manager sees 6 deals across 3 reps, with quotes and discounts.
  - **Next:** the user switches role in CoWork to show the difference live; then a 3:00 end-to-end test and a 3:30 freeze.
- 15:10: CoWork has no role switch in this account. The user's default role was restored to ATTENDEE_ROLE; the governance demo is `sql/07_governance_demo.sql` in a Snowsight worksheet.
- 15:15: The agent's 2,000-agent tipping-point table was mislabeled: Basic rows were shifted down one capability stack. The calculator itself was correct.
  - Real numbers: Customer $234.59 on every row; Basic $114.50 → $184.32 → $224.12 → $263.12 (tipping point at + forecasting + evaluations) → $298.34.
  - Agent v3.1 adds workflow 4b (one calc_tco call per row, exact labels, sanity checks) and the 2,000-agent pattern.

