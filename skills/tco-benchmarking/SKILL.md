---
name: tco-benchmarking
description: Public benchmarks and evidence for contact center TCO conversations: the Forrester TEI of Amazon Connect (Feb 2026), AWS customer quotes, AWS positioning of Customer Basic, and our own validated Customer-vs-Basic scenario results and switch-point rules of thumb. Use when citing numbers, sanity-checking CALC_TCO output against industry figures, or answering "how does this compare to studies?". Always cite the source and its limits.
---

# TCO Benchmarking (evidence the agent may cite)

Built at the Intelligence at Work Hackathon, 2026-10-23. Tag anything from this skill as **BENCHMARK** and cite its source.

## 1. Forrester TEI of Amazon Connect, February 2026
- **Source:** https://d1.awsstatic.com/onedam/marketing-channels/website/aws/en_US/product-categories/contact-center/approved/images/Forrester_TEI_The_Total_Economic_Impact_Of_Amazon_Connect.pdf
- **Required disclosure:** the study was commissioned by AWS; Forrester states it is "not meant to be used as a competitive analysis".

**Composite organization:**
- Global B2C, 2,000 agents, 200 supervisors.
- 20M contacts per year; 75% calls, 25% chat; 30% growth per year.
- AHT 10 min with legacy systems → 8.8 min with Connect (Year 1); 10 messages per chat.

**Headline results:**
- ROI 342%; NPV $78.7M; benefits PV $101.7M; costs PV $23.0M; payback under 6 months.

**Usage cost model (Year 1):**
- 119.68M call minutes × ($0.038 + $0.0106 blended telephony) + 64M chat messages × $0.010 = $6.46M.
- $6.78M after the +5% risk adjustment.

**Derived cost per agent per month (Year 1):**

| Basis | Per agent per month |
|---|---|
| Usage only | **~$269** |
| Risk-adjusted | **~$282** |
| Including migration and ongoing management | **~$303** |

**Reconciling with our calculator:**
- Our `CALC_TCO` gives ~$227 per agent per month for Customer on the same inputs.
- The gap is telephony: we use the $0.0022/min US DID inbound rate; Forrester uses a $0.0106/min blended rate.
- Telephony is the same for Customer and Basic, so it moves the absolute TCO, not the recommendation.

**Benefit benchmarks:**
- Containment +10% per year.
- AHT reduced up to 12%.
- AI post-contact summaries save 60 s per call.
- QA coverage from 1–3% to 100%.
- ML WFM: 5% fewer agents; supervisor span 10 → 12.
- Outbound conversion +20%.

**Legacy cost baseline:** $180 per user per month license + 30% overhead (seat-based, max-concurrent licensing).

**Labor:**
- Agent $45,760 per year fully burdened ($22/h).
- Supervisor $55,800 per year.

**One-time and ongoing costs:**
- Implementation ~$1.2M initial for the composite ($800k professional services).
- Ongoing management ~$0.2–0.3M per year.

**Honest caveat:** some interviewees spent more on Connect than on their legacy vendor, but said they got far more functionality.

## 2. AWS public statements (vendor-published; cite as anecdotal)
- **Flybuys** (AWS pricing page): "50% reduction in our platform costs… all of the AI capability is included in that platform cost."
- **Cochlear** (AWS pricing page): the unlimited AI price replaces separate WFM and QM tools at lower cost.
- **AWS on Basic** (pricing appendix): "Some customers might still be on Customer Basic"; "Not ready for AI?". AWS positions Customer as the strategic offer.

## 3. Our validated scenario results
- **Source:** `CALC_TCO`, price version `AWS-CONNECT-2026-10-23`.
- **Validation:** reproduces AWS pricing example 1 ($4,800.90/month) exactly.
- **Baseline:** 250 agents, default volumes.

| Buyer needs | Customer per agent per month | Basic per agent per month | Cheaper |
|---|---|---|---|
| Voice only, no AI | $262.52 | $132.69 | Basic |
| Voice + chat + email, no AI | $234.59 | $114.50 | Basic |
| Voice only + analytics | $262.52 | $230.06 | Basic |
| Voice only + analytics + agent assist | $262.52 | $275.22 | Customer |
| Omni + analytics + agent assist | $234.59 | $229.23 | about even |
| Omni + analytics + assist + WFM + QA | $234.59 | $268.23 | Customer |
| Omni + everything | $234.59 | $303.45 | Customer |

**Size sensitivity (voice + analytics + assist):**
- 50 agents: Customer $262.52 vs Basic $275.22.
- 2,000 agents: Customer $262.52 vs Basic $265.24.

**Rules of thumb:**
1. **Capabilities decide, not size.** Both options are usage-based.
2. Basic wins for buyers "not ready for AI" or needing analytics only.
3. Customer wins once analytics + agent assist (voice-heavy), or any WFM/QA per-agent add-on, is needed.
4. **Switch point:**
   - Customer's premium over Basic's channel rates is ~$120–130 per agent per month at default volumes.
   - When the Basic add-on bill exceeds that, move to Customer.
   - Customer also unlocks the features Basic can't buy.

## 4. Working assumptions (not benchmarks; tag DEFAULT)
- 168 paid hours per agent per month.
- 30% shrinkage, 80% occupancy.
- Channel mix voice 70% / chat 20% / email 10%.
- Voice: 6-min AHT + 1 min IVR/queue.
- Chat: concurrency 2, 20 messages per chat.
- Email: 8-min AHT.
- 1 DID per 10 agents.
- Agent labor is often cited as 60–70% of contact center cost (rule of thumb; no specific source captured).
