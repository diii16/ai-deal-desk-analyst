# Intelligence at Work Hackathon — Judging Criteria & Rules

Reference document for evaluating `PROJECT_BRIEF.md`. Source: official Participant Guide.

## 1. Problem Statement (what the project must satisfy)

Using **Claude models** and **Snowflake surfaces**, build a working solution that drives a business forward:

- **Measurably** — a concrete, quantifiable improvement
- **For a specific user** — a clearly identified persona
- **Well beyond what a single prompt could reproduce**

Snowflake = the **governed source of truth**. Claude = the **intelligence** that turns that truth into **decisions, actions, or experiences**. The build should show how they **compound and complement** each other.

### Build Themes (pick one)
- **Internal:** Make the business run better — workflows that get people from question to decision faster, or processes that automate recurring multi-step work with fewer handoffs.
- **External:** Change what the business offers — new products or reimagined customer experiences grounded in what the business actually knows.

### Data Requirements
Bring your own data you can responsibly use, in order of preference:
1. A non-production sample, synthetic set, or company-approved extract
2. Public data relevant to your company
3. The fallback dataset (if needed)

- Core data lives in **Snowflake**; auxiliary sources are welcome.
- **Governance must be visible in the build.**

## 2. Judging

### Round One (group rooms)
~3 min live demo + 1–2 min Q&A.

| Criterion | Weight | Judges ask |
|---|---|---|
| **Impact** | 35% | Long-term impact potential? Fits the problem statement? Useful, and for whom? |
| **Demo** | 30% | How well is it implemented? Does it work? |
| **Creativity** | 25% | Is the concept innovative? Is the demo unique? Is the approach non-obvious? |
| **Craft with Snowflake & Claude** | 10% | How effectively were Snowflake and Claude tooling used? Does it go deeper than something reproducible with a single prompt? |

### Round Two (main stage, top 6 teams)
~3 min live demo + 1–2 min Q&A, same four criteria, **equal weighting (25% each)**.

## 3. Rules (disqualification risks)

- **Open source:** Repository must be **public**.
- **Team size:** Max 3 members; solo allowed.
- **Demo scope:** Demo may only highlight features/code/functionality built **during the hackathon**. Judges must clearly identify what was created at the event, or the team is **disqualified**.
- **New work only:** No presenting existing projects; contributions must be clearly distinguished, or the team is **disqualified**.
- **Banned projects:** Anything that violates legal/ethical/platform policies, or uses code, data, or assets you don't have rights to.

### Anti-Projects (strictly not allowed)
- AI Mental Health Advisor
- Basic RAG Applications
- Image Analyzers
- "AI for Education" Chatbot
- AI Job Application Screener
- AI Nutrition Coach
- Personality Analyzers
- Any project using AI to generate and give medical advice
- Any project where a dashboard is the main feature
- Sports analyzers or coaches

## 4. Submission Requirements (due 4:30 PM PT)
- Submit via the Cerebral Valley submission form
- **1-minute demo video** highlighting features/code/functionality built during the hackathon
- Repository is **public**
- Demo link is **accessible**
- **All team members** added to the submission page

## 5. Evaluation Checklist (use against the project brief)

**Problem fit**
- [ ] Uses Claude models AND Snowflake surfaces
- [ ] Specific named user/persona
- [ ] Measurable business outcome (a metric with a baseline and target)
- [ ] Clearly Internal or External theme
- [ ] Snowflake is the governed source of truth; Claude produces decisions/actions/experiences
- [ ] Shows Snowflake + Claude compounding, not just coexisting

**Impact (35%)**
- [ ] Clear who benefits and how much
- [ ] Long-term potential beyond the demo

**Demo (30%)**
- [ ] Working end-to-end flow achievable in today's time window
- [ ] Fits a ~3-minute live demo
- [ ] Contributions built today are clearly identifiable

**Creativity (25%)**
- [ ] Non-obvious concept or approach
- [ ] Distinctive demo moment

**Craft (10%)**
- [ ] Multi-step / agentic, not reproducible with a single prompt
- [ ] Meaningful use of Snowflake features (e.g., Cortex Agents/Analyst/Search, AI functions, Tasks/Streams, Streamlit)
- [ ] Governance visibly demonstrated (roles, masking/row access policies, audit trail)

**Compliance**
- [ ] Not an anti-project (not basic RAG, chatbot, dashboard-centric, etc.)
- [ ] Data is synthetic/public/approved with clear rights
- [ ] Public repo, no secrets committed
- [ ] Submission video plan (1 min)

## 6. Schedule Reference (Fri, Oct 23)
- 11:00 AM — Hacking begins
- 11:00 AM–4:30 PM — Partner technical consultation station
- 4:30 PM — Submissions due
- 4:45 PM — First-round judging
- 5:45 PM — Final round judging
- 6:30 PM — Winners announced
