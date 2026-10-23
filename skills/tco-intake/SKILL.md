---
name: tco-intake
description: Guides a non-expert seller through entering contact center operational data for a TCO, one topic at a time, offering a short menu of cited benchmark options for every value they don't know (paid hours, shrinkage, occupancy, AHT, channel mix, chat messages, IVR time). Use at the start of every new TCO, when the seller says "I don't know", or when they ask "what should I assume?".
---

# TCO Intake (guided operational data input)

Built at the Intelligence at Work Hackathon, 2026-10-23.

## Principles
- **Use the seller's own number whenever they have one** (tag it USER).
- When they don't have a number, offer **2–3 options** with a one-line rationale and source, and recommend one. Tag the choice DEFAULT or BENCHMARK.
- Never ask more than one combined question per turn. If the seller says "just use defaults", use the ★ options and move on.
- Show the chosen value and its tag in the final assumptions table.

## Step 1: The three must-haves (always confirm)
1. **Number of agents.**
   - Any number.
   - If the seller only knows the size: Small 250 (<500), Medium 800 (500–999), Large 2,000 (1,000+).
2. **Channels today, and planned:** voice only / voice + chat / voice + chat + email / SMS or WhatsApp.
3. **Capabilities needed, now and later** (checklist):
   - conversational analytics & post-contact summaries;
   - real-time agent assist;
   - forecasting & scheduling (WFM);
   - agent evaluations (QA);
   - screen recording;
   - self-service bots.

   - Some capabilities are not listed as separately priced items on the AWS pages we captured. We treat them as part of the channel rate in both options and do not model them: routing (incl. skills-based / predictive routing), IVR, call recording, contact search, supervisor barge-in, standard reporting.
   - AWS's FAQ states that call recording, contact search, contact rules, and supervisor barge-in carry no separate charge.
   - Say this instead of guessing a price.

## Step 2: Operational inputs (offer menus only if unknown)

| Input | Option A | Option B | Option C |
|---|---|---|---|
| **Paid hours per agent per month** | ★ 168 h = 8 h × 21 working days (project default) | 173 h = 40 h × 52 weeks ÷ 12 (calendar average) | 176 h = 8 h × 22 days |
| **Shrinkage** (breaks, training, absence, meetings) | ★ 30% (project default; common planning range 25–35%) | 25% (lean operation) | 35% (high training/attrition) |
| **Occupancy** (share of logged-in time spent handling contacts) | ★ 80% (project default) | 75% (small teams, more idle time) | 85% (large, busy centers) |
| **Voice AHT** (talk + hold + after-call work) | ★ 6 min (project default) | 8.8 min (Forrester TEI, Connect Year 1) | 10 min (Forrester TEI, legacy) |
| **IVR / queue time per call** | ★ 1 min (project default) | 0.5 min (simple menu) | 3 min (AWS pricing example 2, queue-heavy) |
| **Channel mix of handle time** | ★ voice 70 / chat 20 / email 10 (project default) | voice 75 / chat 25 (Forrester TEI composite) | voice 100 (voice only) |
| **Messages per chat** (incl. bot/AI messages) | ★ 20 (project default) | 10 (Forrester TEI composite) | 30 (AI-assisted chats with manager assist) |
| **Chat concurrency** | ★ 2 chats at once (project default) | 1 (complex chats) | 3 (simple chats) |
| **Email AHT** | ★ 8 min (project default) | 5 min | 12 min |
| **Inbound share of calls** | ★ 90% (project default) | 100% (pure service) | 70% (sales/outbound-heavy) |

**Source labels:**
- ★ "project default": a working assumption, tagged DEFAULT.
- Forrester TEI options: the Forrester TEI of Amazon Connect, Feb 2026 (commissioned by AWS), tagged BENCHMARK.
- AWS example: the AWS Connect pricing appendix, tagged BENCHMARK.

## Step 3: How volumes are derived (explain when showing results)
1. Handle minutes per agent per month = paid hours × (1 − shrinkage) × occupancy × 60.
   - Default: 168 × 0.70 × 0.80 × 60 = **5,645 min**.
2. Voice calls = agents × handle min × voice share ÷ voice AHT.
3. Billable voice minutes = inbound calls × (AHT + IVR/queue) + outbound calls × AHT.
   - Connect bills the whole call, including IVR and queue time.
4. Chats = agents × handle min × chat share × concurrency ÷ minutes per chat (10).
   - Chat messages = chats × messages per chat.
5. Emails = agents × handle min × email share ÷ email AHT.
6. Phone numbers (DIDs) = agents ÷ 10, billed at $0.03 per day × 30 days.

The default tool `get_default_profile` uses the ★ options. When the seller picks other options, recompute these volumes in plain steps from the formulas above, show the arithmetic, and pass the resulting volumes to `calc_tco`.

## Step 4: Confirm before calculating
Summarize the inputs in one compact table (input | value | tag | source). Then calculate immediately, unless the seller wants to change something.
