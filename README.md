# AI Deal Desk Analyst for Contact Center Resellers

**Intelligence at Work Hackathon, 23 Oct 2026. Solo project. Everything in this repo was built during the hackathon.**

A Claude-powered Cortex Agent in Snowflake CoWork that helps non-expert resellers answer a hard pre-sales question:
*should this buyer get Amazon Connect Customer or Customer Basic, what will it cost, and when should they switch?*
A complex contact center TCO typically takes a consultant 40–80 hours. With this agent, any seller gets a defensible
first-pass answer, with sources and math, in under 15 minutes.

## What it does
- **Guided intake:** the seller gives agents, channels and capabilities. Anything unknown gets a default or a benchmark menu (Forrester TEI, AWS examples) with a recommended option.
- **Deterministic pricing:** every dollar comes from a governed, effective-dated price catalog (price version `AWS-CONNECT-2026-10-23`) via a SQL calculator. Claude never computes prices itself.
- **Deal brief:** a recommendation, side-by-side TCO, cost layers with a chart, the switch point, tagged assumptions, a seller talk track, "how we calculated this" with source URLs, and caveats.
- **Governed saved deals:** sellers save analyses. A row access policy limits reps to their own deals, and a masking policy hides discount pricing from reps; managers see everything.

Key insight from the model: **capabilities decide, not size.** Customer bundles AI in its per-minute rate, so its cost is flat at about $235 per agent per month. Basic is cheaper until the buyer needs paid add-ons. Customer wins once they need analytics + agent assist + forecasting/scheduling + evaluations.

## Architecture (Snowflake, database `CX_TCO.CORE`)
| Layer | Built today |
|---|---|
| Surface | Snowflake CoWork / Snowflake Intelligence (no custom front end) |
| Agent | Cortex Agent `DEAL_DESK_ANALYST` on `claude-sonnet-4-5` (`sql/05_agent.sql`) |
| Tools | Stored procedures `GET_DEFAULT_PROFILE`, `CALC_TCO`, `SAVE_ANALYSIS`, `LIST_DEALS`, plus `data_to_chart` |
| Data | `PRICE_CATALOG` (35 list prices from AWS public pricing pages), `FEATURE_MAP`, `SCENARIOS`, `ANALYSES` (synthetic deals only) |
| Calculator | SQL UDTF `CALC_TCO_LINES`; validated against AWS pricing example 1 ($4,800.90, exact match) |
| Governance | Roles `DEALDESK_REP` / `DEALDESK_MANAGER`, row access policy `DEAL_OWNER_POLICY`, masking policy `DEAL_PRICE_MASK`, caller's-rights tools |
| Method | Agent skills in `skills/` (intake, modeling, benchmarking), embedded in the agent instructions |

## Repo map
- `sql/01_setup_and_load.sql`: schema and price catalog load
- `sql/02_calculator.sql`: volume view, UDTF calculator, `CALC_TCO`, `GET_DEFAULT_PROFILE`
- `sql/05_agent.sql`: Cortex Agent specification
- `sql/06_governance.sql`: saved deals, roles, policies, save/list tools
- `sql/07_governance_demo.sql`: 30-second rep vs manager demo
- `skills/`: `tco-intake`, `tco-modeling`, `tco-benchmarking`
- `PROJECT_BRIEF.md`, `PROJECT_DETAILS.md`, `TALK_TRACK.md`: plan, results and evidence, pitch

## Deploy
Run the SQL files in order (01, 02, 05, 06) with a role that can create databases, roles and policies. Then open the agent in CoWork.

## Sources and caveats
- Pricing: https://aws.amazon.com/products/connect/customer/pricing/ and https://aws.amazon.com/products/connect/customer/pricing/appendix/ (fetched 23 Oct 2026).
- Benchmark: Forrester TEI of Amazon Connect (commissioned by AWS).
- List prices only. Excludes taxes, Lex/Polly, implementation and agent labor. A first-pass estimate, not a quote. All deal data is synthetic.

## Roadmap
Self-maintaining price catalog (a weekly Task where Claude proposes price changes for human approval), multi-vendor comparisons, an RFP accelerator, a benchmarks network, and sellers' everyday tools via MCP.
