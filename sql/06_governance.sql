-- Phase 6: Governance: saved analyses, demo roles, row access + masking policies, save/list tools
-- Built at the Intelligence at Work Hackathon, 2026-10-23.
USE SCHEMA CX_TCO.CORE;

-- ---------------------------------------------------------------
-- Saved analyses (each pinned to a price version for replicability)
-- ---------------------------------------------------------------
CREATE OR REPLACE TABLE ANALYSES (
    analysis_id          STRING DEFAULT UUID_STRING(),
    rep_name             STRING,          -- owning seller (drives row access)
    deal_name            STRING,
    agents               NUMBER,
    channels             STRING,
    capabilities         STRING,
    recommendation       STRING,
    customer_annual_usd  NUMBER(14,2),
    basic_annual_usd     NUMBER(14,2),
    quoted_discount_pct  NUMBER(5,2),     -- private deal pricing (masked for reps)
    quoted_annual_usd    NUMBER(14,2),    -- private deal pricing (masked for reps)
    price_version        STRING DEFAULT 'AWS-CONNECT-2026-10-23',
    notes                STRING,
    created_by           STRING DEFAULT CURRENT_USER(),
    created_role         STRING DEFAULT CURRENT_ROLE(),
    created_at           TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Seed: synthetic demo deals from three sellers (no real customer data)
INSERT INTO ANALYSES (rep_name, deal_name, agents, channels, capabilities, recommendation, customer_annual_usd, basic_annual_usd, quoted_discount_pct, quoted_annual_usd, notes)
VALUES
('Jordan Lee', 'Acme Insurance (synthetic)', 250, 'VOICE_ONLY', 'none', 'CONNECT_BASIC', 787560, 398070, 8, 366224, 'Not ready for AI; revisit at analytics adoption'),
('Jordan Lee', 'Northwind Retail (synthetic)', 300, 'OMNI', 'analytics, assist, WFM, QA', 'CONNECT_CUSTOMER', 844532, 965626, 10, 760079, 'Customer wins on parity'),
('Jordan Lee', 'Bluebird Health (synthetic)', 120, 'OMNI', 'analytics', 'CONNECT_BASIC', 337781, 284000, 5, 269800, NULL),
('Priya Shah', 'Globex Telecom (synthetic)', 2000, 'OMNI', 'analytics, assist, WFM, QA', 'CONNECT_CUSTOMER', 5630206, 6314861, 15, 4785675, 'Large omni; strong AI case'),
('Priya Shah', 'Initech Banking (synthetic)', 800, 'OMNI', 'analytics, assist, WFM, QA', 'CONNECT_CUSTOMER', 2252083, 2575003, 12, 1981833, NULL),
('Sam Ortiz', 'Umbrella Utilities (synthetic)', 500, 'VOICE_ONLY', 'analytics, assist', 'CONNECT_CUSTOMER', 1575120, 1651320, 7, 1464862, 'Near the switch point');

-- ---------------------------------------------------------------
-- Demo roles
-- ---------------------------------------------------------------
CREATE ROLE IF NOT EXISTS DEALDESK_REP     COMMENT = 'Demo: seller Jordan Lee - sees own deals, no discount pricing';
CREATE ROLE IF NOT EXISTS DEALDESK_MANAGER COMMENT = 'Demo: deal desk manager - sees all deals and discount pricing';
GRANT ROLE DEALDESK_REP TO USER "USER";
GRANT ROLE DEALDESK_MANAGER TO USER "USER";

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEALDESK_REP;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON WAREHOUSE DEFAULT_WH TO ROLE DEALDESK_REP;
GRANT USAGE ON WAREHOUSE DEFAULT_WH TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON DATABASE CX_TCO TO ROLE DEALDESK_REP;
GRANT USAGE ON DATABASE CX_TCO TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON SCHEMA CX_TCO.CORE TO ROLE DEALDESK_REP;
GRANT USAGE ON SCHEMA CX_TCO.CORE TO ROLE DEALDESK_MANAGER;
GRANT SELECT ON ALL TABLES IN SCHEMA CX_TCO.CORE TO ROLE DEALDESK_REP;
GRANT SELECT ON ALL TABLES IN SCHEMA CX_TCO.CORE TO ROLE DEALDESK_MANAGER;
GRANT INSERT ON TABLE ANALYSES TO ROLE DEALDESK_REP;
GRANT INSERT ON TABLE ANALYSES TO ROLE DEALDESK_MANAGER;

-- ---------------------------------------------------------------
-- Row access: reps see only their own deals; manager / admin see all
-- (CURRENT_ROLE() is used rather than IS_ROLE_IN_SESSION so secondary roles don't leak access in the demo)
-- ---------------------------------------------------------------
CREATE OR REPLACE ROW ACCESS POLICY DEAL_OWNER_POLICY AS (rep STRING) RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('DEALDESK_MANAGER', 'ATTENDEE_ROLE', 'ACCOUNTADMIN')
    OR (CURRENT_ROLE() = 'DEALDESK_REP' AND rep = 'Jordan Lee');
ALTER TABLE ANALYSES ADD ROW ACCESS POLICY DEAL_OWNER_POLICY ON (rep_name);

-- ---------------------------------------------------------------
-- Masking: private quoted / discount pricing hidden from reps
-- ---------------------------------------------------------------
CREATE OR REPLACE MASKING POLICY DEAL_PRICE_MASK AS (val NUMBER) RETURNS NUMBER ->
    CASE WHEN CURRENT_ROLE() IN ('DEALDESK_MANAGER', 'ATTENDEE_ROLE', 'ACCOUNTADMIN') THEN val ELSE NULL END;
ALTER TABLE ANALYSES MODIFY COLUMN quoted_discount_pct SET MASKING POLICY DEAL_PRICE_MASK;
ALTER TABLE ANALYSES MODIFY COLUMN quoted_annual_usd   SET MASKING POLICY DEAL_PRICE_MASK;

-- ---------------------------------------------------------------
-- Agent tools (caller's rights, so policies apply to the CoWork user's role)
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SAVE_ANALYSIS(
    deal_name STRING, agents NUMBER, channels STRING, capabilities STRING, recommendation STRING,
    customer_annual_usd FLOAT, basic_annual_usd FLOAT, notes STRING)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Saves a TCO analysis for the current seller, pinned to price version AWS-CONNECT-2026-10-23.'
EXECUTE AS CALLER
AS
$$
DECLARE
    new_id STRING DEFAULT UUID_STRING();
    rep STRING;
BEGIN
    rep := IFF(CURRENT_ROLE() = 'DEALDESK_REP', 'Jordan Lee', CURRENT_USER());
    INSERT INTO CX_TCO.CORE.ANALYSES (analysis_id, rep_name, deal_name, agents, channels, capabilities, recommendation,
                                      customer_annual_usd, basic_annual_usd, notes)
    VALUES (:new_id, :rep, :deal_name, :agents, :channels, :capabilities, :recommendation,
            :customer_annual_usd, :basic_annual_usd, :notes);
    RETURN OBJECT_CONSTRUCT('saved', TRUE, 'analysis_id', new_id, 'rep_name', rep, 'role', CURRENT_ROLE(),
                            'price_version', 'AWS-CONNECT-2026-10-23');
END;
$$;

CREATE OR REPLACE PROCEDURE LIST_DEALS()
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Lists saved TCO analyses visible to the current role (row access and masking policies apply).'
EXECUTE AS CALLER
AS
$$
DECLARE
    deals VARIANT;
BEGIN
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT_KEEP_NULL(
             'deal_name', deal_name, 'rep_name', rep_name, 'agents', agents, 'channels', channels,
             'capabilities', capabilities, 'recommendation', recommendation,
             'customer_annual_usd', customer_annual_usd, 'basic_annual_usd', basic_annual_usd,
             'quoted_discount_pct', quoted_discount_pct, 'quoted_annual_usd', quoted_annual_usd,
             'price_version', price_version, 'created_at', created_at)) WITHIN GROUP (ORDER BY created_at DESC)
      INTO :deals
      FROM CX_TCO.CORE.ANALYSES;
    RETURN OBJECT_CONSTRUCT('viewing_role', CURRENT_ROLE(), 'deal_count', ARRAY_SIZE(COALESCE(deals, ARRAY_CONSTRUCT())),
                            'deals', COALESCE(deals, ARRAY_CONSTRUCT()),
                            'governance_note', 'Row access policy DEAL_OWNER_POLICY limits reps to their own deals; masking policy DEAL_PRICE_MASK hides quoted/discount pricing from reps.');
END;
$$;

-- Tool + agent access for both roles
GRANT USAGE ON PROCEDURE SAVE_ANALYSIS(STRING, NUMBER, STRING, STRING, STRING, FLOAT, FLOAT, STRING) TO ROLE DEALDESK_REP;
GRANT USAGE ON PROCEDURE SAVE_ANALYSIS(STRING, NUMBER, STRING, STRING, STRING, FLOAT, FLOAT, STRING) TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON PROCEDURE LIST_DEALS() TO ROLE DEALDESK_REP;
GRANT USAGE ON PROCEDURE LIST_DEALS() TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON PROCEDURE CALC_TCO(NUMBER, NUMBER, FLOAT, FLOAT, FLOAT, NUMBER, FLOAT, NUMBER, NUMBER, NUMBER, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) TO ROLE DEALDESK_REP;
GRANT USAGE ON PROCEDURE CALC_TCO(NUMBER, NUMBER, FLOAT, FLOAT, FLOAT, NUMBER, FLOAT, NUMBER, NUMBER, NUMBER, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON PROCEDURE GET_DEFAULT_PROFILE(NUMBER, STRING) TO ROLE DEALDESK_REP;
GRANT USAGE ON PROCEDURE GET_DEFAULT_PROFILE(NUMBER, STRING) TO ROLE DEALDESK_MANAGER;
GRANT USAGE ON AGENT DEAL_DESK_ANALYST TO ROLE DEALDESK_REP;
GRANT USAGE ON AGENT DEAL_DESK_ANALYST TO ROLE DEALDESK_MANAGER;
