# Talk Track & Pitch Notes — AI Deal Desk Analyst

Living document. Final version to be drafted at 3:30. Judging: ~3 min live (demo + vision) + 1–2 min Q&A.
Target split: **~2:15 demo, ~0:45 vision.**

## 1. Opening hook (~20 s)
- "A complex contact center TCO takes a specialist consultant **40–80 hours**, and very few people can do it."
- "So most sellers can't talk cost early in the deal. RFPs stall, or someone guesses."
- "We built an AI Deal Desk Analyst that lets **any seller** produce a first-pass, source-cited TCO in **under 15 minutes**."

## 2. Demo beats (~2:15)
1. **Paste discovery notes** into the Deal Desk agent in CoWork (a messy, realistic paragraph).
2. **Guided intake.** The agent asks only for what's missing and proposes labeled defaults ("I assumed 6-minute AHT, a DEFAULT; change it?").
3. **Governed calculation.** The agent calls the cost tool. "Claude never invents a price. Every number comes from the effective-dated price catalog in Snowflake, with a source URL."
4. **Recommendation plus capability parity.**
   - Example: "Basic looks cheaper on channel rates, but once you add forecasting, evaluations, and analytics to match Customer, Customer wins at this size."
5. **Wow moment:** "Actually they also need email." The agent re-runs and explains how the recommendation shifted.
6. **Deal brief artifact:** chart, cost breakdown, assumptions tagged USER / DEFAULT / BENCHMARK, and a seller talk track.
7. **Governance:** switch role. Rep B can't see Rep A's deals (row access policy); discount pricing is masked for junior reps.
8. Optional (if time): the agent trace showing the multi-step tool calls.

## 3. Vision (~45 s)
1. **Self-maintaining price catalog.**
   - A weekly Snowflake Task re-reads vendor pricing pages, and Claude spots changes.
   - It drafts a new price version, and a human approves it.
   - Saved deals can be re-priced at today's rates.
2. **Multi-vendor, apples to apples.** Genesys next, then NICE, Five9, Talkdesk, and others. Same demand profile, same outputs, and a cross-vendor capability map.
3. **RFP accelerator.** Upload an RFP PDF and get a draft pricing/TCO response.
4. **Benchmark network.** Anonymized, consented benchmarks by industry, size, and region, plus licensed analyst content.
5. **Everywhere sellers work.** Teams, Claude Desktop (MCP), and CRM: the same governed agent.

## 4. Proof points / talking points (public sources)
- **Headline insight (ours, from the calculator):** "Capabilities decide, not size."
  - Basic is up to ~50% cheaper for a buyer that isn't ready for AI.
  - Add agent assist, forecasting, or quality evaluations, and Customer becomes ~13% cheaper and unlocks features Basic can't buy.
  - Full table: `PROJECT_DETAILS.md` §3.
- **Validation line:** "Our engine reproduces AWS's own published pricing example to the cent: $4,800.90."
- **Forrester TEI (commissioned by AWS):**
  - 342% ROI, payback under 6 months.
  - Their composite works out to ~$300 per agent per month all-in.
  - Our estimate runs lower only because of telephony assumptions.
- **AWS positions Customer Basic as legacy** ("Some customers might still be on Customer Basic"; "Not ready for AI?"). Customer is the strategic offer.
- **Flybuys** (AWS pricing page): "We have seen a **50% reduction in our platform costs**… all of the AI capability is included in that platform cost."
- **Cochlear** (AWS pricing page): the unlimited AI price replaces separate WFM and quality-management tools, at lower cost.
- **Customer pricing model:** no seat licenses, no minimums, no tokens; all AI is included in the channel rate.
- **Forrester TEI of Amazon Connect** (linked from the pricing page). Headline numbers are not yet captured; read them from the PDF before quoting.
- **IDC MarketScape:** Worldwide Agentic CCaaS Platforms 2026 (listed on the overview page).
- **Neutrality line:** "We resell both vendors, so the methodology is transparent and every assumption is editable."

## 5. Why this is more than one prompt (Craft)
- Multi-step agent: intake → extraction → tool call (SQL cost engine) → parity check → write-back → artifact.
- Snowflake supplies governed truth: an effective-dated catalog, price versions, RBAC, row access and masking policies, and an audit trail of saved analyses.
- Claude supplies judgment: asking the right questions, explaining trade-offs, and writing for a non-expert seller.

## 6. Likely Q&A
| Question | Answer |
|---|---|
| **"How do you know the prices are right?"** | Every row has a source URL and a price version, fetched today from the AWS public pages. The calculation is deterministic SQL, not the LLM |
| **"What about telephony?"** | The MVP uses published US rates (DID, inbound, outbound). The full global table is on the roadmap |
| **"What did you build today?"** | Everything in the repo: tables, cost procedure, agent, policies, evals. The README lists it |
| **"Isn't the reseller biased?"** | It shows list prices only, a transparent method, capability-parity notes, and discloses the reseller relationship |
| **"Why not just a spreadsheet?"** | A spreadsheet needs an expert to drive it. Here the agent guides a non-expert, explains the result, and saves a governed, replicable analysis |

## 7. 1-minute submission video outline
1. 0:00–0:10: the problem (40–80 hours, few experts).
2. 0:10–0:45: notes → agent → recommendation → email flip → deal brief.
3. 0:45–0:55: governance role switch.
4. 0:55–1:00: vision line + "built today on Snowflake Cortex Agents + Claude".
