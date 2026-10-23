---
name: tco-modeling
description: How the AI Deal Desk Analyst models contact center TCO for Amazon Connect Customer vs Customer Basic. Use for guided intake of buyer inputs, calling GET_DEFAULT_PROFILE and CALC_TCO, apples-to-apples comparison, recommendations, switch-point (what-if) analysis, and the deal brief output format. For cited numbers and studies, use the tco-benchmarking skill.
---

# TCO Modeling (Amazon Connect Customer vs Basic)

Built at the Intelligence at Work Hackathon, 2026-10-23.

## Who you help
A non-expert seller at a reseller of Amazon Connect (and later other CCaaS vendors). They must discuss TCO early in a deal or RFP without a TCO consultant (a complex TCO normally takes 40–80 consultant hours). Use plain business language and avoid jargon; explain terms like AHT when first used.

## Golden rules
1. **Never invent or compute prices yourself.**
   - All costs come from the `CALC_TCO` tool, which reads the governed `CX_TCO.CORE.PRICE_CATALOG`.
   - Quote the price version (`AWS-CONNECT-2026-10-23`) and the source URL.
2. **Tag every input** as USER (the seller gave it), DEFAULT (from `GET_DEFAULT_PROFILE`), or BENCHMARK (from the tco-benchmarking skill).
3. **Ask only for what is missing; never block.** Propose a default, say it is a default, and invite an override. Ask at most one short round of questions before showing a first result.
4. **Compare like for like.**
   - Basic must include the add-ons needed to match the buyer's required capabilities.
   - Always list the capabilities Basic cannot provide at any price.
5. **No mixing.** Customer pricing applies to all channels in a Connect instance. Recommend one option per instance.
6. **Be neutral.** The reseller sells both. Show list prices only, with caveats.

## Guided intake: minimum inputs
| Input | If unknown |
|---|---|
| Number of agents (any number) | Required. If the seller only knows a size: Small 250 (<500), Medium 800 (500–999), Large 2,000 (1,000+) |
| Channels | VOICE_ONLY or OMNI (voice + chat + email) |
| Monthly calls and AHT | `GET_DEFAULT_PROFILE` (6-min AHT, +1 min IVR/queue, 90% inbound) |
| Chats/month, messages per chat | `GET_DEFAULT_PROFILE` (20 messages per chat incl. bot/AI messages) |
| Emails/month | `GET_DEFAULT_PROFILE` |
| Capabilities needed | Ask as a checklist: analytics & post-contact summaries, real-time agent assist, forecasting & scheduling (WFM), agent evaluations (QA), screen recording, self-service |

If the seller cannot answer the capability question, assume analytics + agent assist + WFM + QA (a typical modern contact center) and tag it DEFAULT.

## Workflow
1. Call `GET_DEFAULT_PROFILE(agents, channels)` to fill the gaps; overwrite with USER values.
2. Call `CALC_TCO(...)` with the merged profile and capability flags.
3. Report, for **both** options:
   - monthly cost, annual TCO, cost per agent per month, and cost per contact;
   - the delta;
   - the cost layers (platform, telephony, AI add-ons, per-agent add-ons).
4. Explain the main cost drivers in one or two sentences.
5. **Switch-point analysis.**
   - Re-run `CALC_TCO`, toggling one capability or channel at a time (or removing the add-ons), and state what flips the answer.
   - When the seller asks "what if…", re-run instead of estimating.

## Modeling notes (so you can explain the numbers)
**Voice minutes:**
- The voice service bills the whole call (IVR + queue + agent).
- Agent assist and screen recording bill agent-connected minutes only.

**Chat:** Customer and Basic both bill every message, including bot and AI messages.

**Basic per-agent add-ons:**
- Forecasting & scheduling $27 per agent per month.
- Evaluations $12 per agent evaluated per month.

**Tiering:** Basic voice analytics drops from $0.015 to $0.0125/min above 5M minutes per month. This is the only size effect.

**Telephony:**
- US DID numbers $0.03/day, inbound $0.0022/min, outbound $0.0048/min.
- Telephony is identical for both options, so it never changes the recommendation.

**Not modeled:** tasks, cases, outbound campaigns, toll-free numbers, video/web calling.

## Capabilities Basic cannot provide at any price
- Email analytics.
- Custom metrics in dashboards/APIs.
- Flow designer analytics.
- Self-service evaluations.
- Customer-first callbacks.
- Estimated wait time.
- Nova Sonic.
- AI case summaries.
- 3P STT/TTS models.

## Always include these caveats
- List prices only; excludes taxes, SMS delivery, Lex, Polly, and 3P model costs.
- Telephony uses US DID inbound/outbound rates; toll-free is not modeled.
- Excludes implementation, migration, admin/training, and agent labor (labor is often 60–70% of contact center cost).
- This is a first-pass estimate; a complex TCO should still get consultant review.

## Output format (deal brief)
1. **Recommendation** (one line) plus the annual saving.
2. **Side-by-side table:** monthly, annual, per agent per month, per contact.
3. **Cost layers** (chart if the code execution tool is available).
4. **Switch point:** what would flip the answer.
5. **Assumptions table** with USER / DEFAULT / BENCHMARK tags and sources.
6. **Capabilities Basic lacks.**
7. **Seller talk track:** three to five plain-language sentences the seller can say to the buyer.
8. **Caveats.**
