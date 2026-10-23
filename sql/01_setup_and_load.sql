-- Phase 1: database, reference tables, and seed data
-- Built at the Intelligence at Work Hackathon, 2026-10-23.
-- Source for all prices: AWS public pages fetched 2026-10-23.

CREATE DATABASE IF NOT EXISTS CX_TCO;
CREATE SCHEMA IF NOT EXISTS CX_TCO.CORE;
USE SCHEMA CX_TCO.CORE;

-- ---------------------------------------------------------------
-- PRICE_CATALOG: effective-dated list prices (one row per priced component)
-- ---------------------------------------------------------------
CREATE OR REPLACE TABLE PRICE_CATALOG (
    vendor          STRING,
    product         STRING,   -- CONNECT_CUSTOMER | CONNECT_BASIC | TELEPHONY_US
    component       STRING,   -- e.g. CHANNEL_USAGE, CONV_ANALYTICS, FORECASTING
    channel         STRING,   -- VOICE | CHAT | MESSAGING | EMAIL | ALL
    unit            STRING,   -- PER_MIN | PER_MESSAGE | PER_EMAIL | PER_AGENT_MONTH | PER_NUMBER_DAY ...
    price           NUMBER(12,5),
    tier_min        NUMBER,   -- monthly volume tier start (NULL = no tiering)
    tier_max        NUMBER,
    region          STRING,
    currency        STRING,
    price_version   STRING,
    effective_from  DATE,
    effective_to    DATE,
    source_url      STRING,
    notes           STRING,
    loaded_at       TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

SET pv  = 'AWS-CONNECT-2026-10-23';
SET app = 'https://aws.amazon.com/products/connect/customer/pricing/appendix/';

INSERT INTO PRICE_CATALOG (vendor, product, component, channel, unit, price, tier_min, tier_max, region, currency, price_version, effective_from, effective_to, source_url, notes)
SELECT 'AMAZON', column1, column2, column3, column4, column5, column6, column7, 'NA', 'USD', $pv, '2026-10-23'::DATE, NULL, $app, column8
FROM VALUES
-- Connect Customer: all AI capabilities included in channel rates
('CONNECT_CUSTOMER','CHANNEL_USAGE','VOICE','PER_MIN',0.038,NULL,NULL,'Voice service; covers IVR, queue and agent time. Per second, 10s min. Telephony extra'),
('CONNECT_CUSTOMER','CHANNEL_USAGE','CHAT','PER_MESSAGE',0.010,NULL,NULL,'Counts customer, agent, AI and manager-assist messages'),
('CONNECT_CUSTOMER','CHANNEL_USAGE','MESSAGING','PER_MESSAGE',0.014,NULL,NULL,'SMS/Apple/WhatsApp; SMS delivery fees extra'),
('CONNECT_CUSTOMER','CHANNEL_USAGE','EMAIL','PER_EMAIL',0.080,NULL,NULL,NULL),
('CONNECT_CUSTOMER','OUTBOUND_CAMPAIGNS','VOICE','PER_MIN',0.045,NULL,NULL,'Replaces the 0.038 voice rate for campaign minutes'),
('CONNECT_CUSTOMER','WEB_AUDIO','VOICE','PER_MIN',0.010,NULL,NULL,'In-app / web calling audio'),
('CONNECT_CUSTOMER','VIDEO','VOICE','PER_MIN',0.015,NULL,NULL,'Per participant'),
('CONNECT_CUSTOMER','SCREEN_SHARE','VOICE','PER_MIN',0.015,NULL,NULL,NULL),
('CONNECT_CUSTOMER','TASKS','ALL','PER_TASK',0.070,NULL,NULL,'Out of MVP scope'),
('CONNECT_CUSTOMER','GUIDES','ALL','PER_MESSAGE',0.010,NULL,NULL,'Step-by-step guides; out of MVP scope'),
('CONNECT_CUSTOMER','CASES','ALL','PER_CASE',0.120,NULL,NULL,'AI case summaries included; out of MVP scope'),
('CONNECT_CUSTOMER','EXTERNAL_VOICE','VOICE','PER_MIN',0.032,NULL,NULL,'Plus 100 USD per connector per day'),
-- Connect Basic (a la carte)
('CONNECT_BASIC','CHANNEL_USAGE','VOICE','PER_MIN',0.018,NULL,NULL,'Inbound and outbound. Telephony extra'),
('CONNECT_BASIC','CHANNEL_USAGE','CHAT','PER_MESSAGE',0.004,NULL,NULL,NULL),
('CONNECT_BASIC','CHANNEL_USAGE','MESSAGING','PER_MESSAGE',0.010,NULL,NULL,'SMS delivery fees extra'),
('CONNECT_BASIC','CHANNEL_USAGE','EMAIL','PER_EMAIL',0.050,NULL,NULL,NULL),
('CONNECT_BASIC','CONV_ANALYTICS','VOICE','PER_MIN',0.015,0,5000000,'Tier 1: first 5M min/month; includes post-contact summaries'),
('CONNECT_BASIC','CONV_ANALYTICS','VOICE','PER_MIN',0.0125,5000000,NULL,'Tier 2: above 5M min/month'),
('CONNECT_BASIC','CONV_ANALYTICS','CHAT','PER_MESSAGE',0.0015,NULL,NULL,NULL),
('CONNECT_BASIC','CONV_ANALYTICS','MESSAGING','PER_MESSAGE',0.0015,NULL,NULL,NULL),
('CONNECT_BASIC','SELF_SERVICE','VOICE','PER_MIN',0.008,NULL,NULL,'Plus Lex charges'),
('CONNECT_BASIC','SELF_SERVICE','CHAT','PER_MESSAGE',0.0015,NULL,NULL,'Plus Lex charges'),
('CONNECT_BASIC','SELF_SERVICE','MESSAGING','PER_MESSAGE',0.0015,NULL,NULL,'Plus Lex charges'),
('CONNECT_BASIC','AGENT_ASSIST','VOICE','PER_MIN',0.008,NULL,NULL,NULL),
('CONNECT_BASIC','AGENT_ASSIST','CHAT','PER_MESSAGE',0.0015,NULL,NULL,NULL),
('CONNECT_BASIC','AGENT_ASSIST','MESSAGING','PER_MESSAGE',0.0015,NULL,NULL,NULL),
('CONNECT_BASIC','AGENT_ASSIST','EMAIL','PER_EMAIL',0.020,NULL,NULL,'Per inbound email'),
('CONNECT_BASIC','SCREEN_RECORDING','VOICE','PER_MIN',0.006,NULL,NULL,'Agent-connected + after-contact work only, not IVR'),
('CONNECT_BASIC','FORECASTING','ALL','PER_AGENT_MONTH',27.00,NULL,NULL,'Forecasting, capacity planning and scheduling'),
('CONNECT_BASIC','EVALUATIONS','ALL','PER_AGENT_MONTH',12.00,NULL,NULL,'Per agent evaluated per month; human-handled contacts only'),
('CONNECT_BASIC','CASES','ALL','PER_CASE',0.120,NULL,NULL,'No AI case summaries; out of MVP scope'),
('CONNECT_BASIC','EXTERNAL_VOICE','VOICE','PER_MIN',0.012,NULL,NULL,'Plus 100 USD per connector per day'),
-- Telephony (US, us-west-2), applies to both products
('TELEPHONY_US','DID_NUMBER','VOICE','PER_NUMBER_DAY',0.030,NULL,NULL,'From AWS worked examples; full Global Telephony table not captured'),
('TELEPHONY_US','INBOUND_DID','VOICE','PER_MIN',0.0022,NULL,NULL,'Per second, 60s min. From AWS worked examples'),
('TELEPHONY_US','OUTBOUND_US','VOICE','PER_MIN',0.0048,NULL,NULL,'Per second, 60s min. From AWS worked examples');

-- ---------------------------------------------------------------
-- FEATURE_MAP: capability parity (INCLUDED / ADDON / NOT_AVAILABLE)
-- ---------------------------------------------------------------
CREATE OR REPLACE TABLE FEATURE_MAP (
    capability      STRING,
    capability_name STRING,
    product         STRING,
    status          STRING,
    addon_component STRING,   -- joins to PRICE_CATALOG.component when status = ADDON
    channel_notes   STRING,
    price_version   STRING,
    source_url      STRING
);

INSERT INTO FEATURE_MAP
SELECT column1, column2, column3, column4, column5, column6, $pv, $app
FROM VALUES
('CONV_ANALYTICS','Conversational analytics & post-contact summaries','CONNECT_CUSTOMER','INCLUDED',NULL,'Voice, chat, messaging, email'),
('CONV_ANALYTICS','Conversational analytics & post-contact summaries','CONNECT_BASIC','ADDON','CONV_ANALYTICS','Voice, chat, messaging only; no email analytics'),
('SELF_SERVICE','End-customer self-service (incl. Lex)','CONNECT_CUSTOMER','INCLUDED',NULL,'Voice, chat, messaging; not email'),
('SELF_SERVICE','End-customer self-service','CONNECT_BASIC','ADDON','SELF_SERVICE','Plus Lex charges; not email'),
('AGENT_ASSIST','Real-time agent assistance','CONNECT_CUSTOMER','INCLUDED',NULL,'All channels'),
('AGENT_ASSIST','Real-time agent assistance','CONNECT_BASIC','ADDON','AGENT_ASSIST','All channels'),
('FORECASTING','Forecasting & agent scheduling','CONNECT_CUSTOMER','INCLUDED',NULL,'Not offered for email'),
('FORECASTING','Forecasting & agent scheduling','CONNECT_BASIC','ADDON','FORECASTING','Per agent per month'),
('EVALUATIONS','Performance evaluations of agents','CONNECT_CUSTOMER','INCLUDED',NULL,'All channels'),
('EVALUATIONS','Performance evaluations of agents','CONNECT_BASIC','ADDON','EVALUATIONS','Per agent evaluated; human-handled contacts only'),
('SCREEN_RECORDING','Screen recording','CONNECT_CUSTOMER','INCLUDED',NULL,'Not email'),
('SCREEN_RECORDING','Screen recording','CONNECT_BASIC','ADDON','SCREEN_RECORDING','Voice agent time only'),
('EMAIL_ANALYTICS','Conversational analytics for email','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('EMAIL_ANALYTICS','Conversational analytics for email','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('CUSTOM_METRICS','Custom metrics in dashboards and APIs','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('CUSTOM_METRICS','Custom metrics in dashboards and APIs','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('FLOW_ANALYTICS','Flow designer analytics','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('FLOW_ANALYTICS','Flow designer analytics','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('SELF_SERVICE_EVALS','Performance evaluations of self-service interactions','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('SELF_SERVICE_EVALS','Performance evaluations of self-service interactions','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('CALLBACKS','Customer-first callbacks','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('CALLBACKS','Customer-first callbacks','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('EST_WAIT_TIME','Estimated wait time','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('EST_WAIT_TIME','Estimated wait time','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('NOVA_SONIC','Amazon Nova Sonic (agentic voice)','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('NOVA_SONIC','Amazon Nova Sonic (agentic voice)','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('AI_CASE_SUMMARY','AI-powered case summarization','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('AI_CASE_SUMMARY','AI-powered case summarization','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('THIRD_PARTY_STT_TTS','3P speech-to-text / text-to-speech models','CONNECT_CUSTOMER','INCLUDED',NULL,'3P provider costs extra'),
('THIRD_PARTY_STT_TTS','3P speech-to-text / text-to-speech models','CONNECT_BASIC','NOT_AVAILABLE',NULL,NULL),
('GENERATIVE_TTS','Polly generative text-to-speech','CONNECT_CUSTOMER','INCLUDED',NULL,NULL),
('GENERATIVE_TTS','Polly generative text-to-speech','CONNECT_BASIC','ADDON',NULL,'Billed separately by Polly; not modeled');

-- ---------------------------------------------------------------
-- SCENARIOS: default demand profiles (agreed 2026-10-23, all tagged DEFAULT)
-- ---------------------------------------------------------------
CREATE OR REPLACE TABLE SCENARIOS (
    size_code             STRING,
    size_band             STRING,
    agents                NUMBER,
    paid_hours_per_agent  NUMBER,
    shrinkage_pct         NUMBER(5,2),
    occupancy_pct         NUMBER(5,2),
    voice_share_pct       NUMBER(5,2),
    chat_share_pct        NUMBER(5,2),
    email_share_pct       NUMBER(5,2),
    voice_aht_min         NUMBER(6,2),
    ivr_queue_min_per_call NUMBER(6,2),
    inbound_share_pct     NUMBER(5,2),
    chat_min_per_chat     NUMBER(6,2),
    chat_concurrency      NUMBER(4,1),
    messages_per_chat     NUMBER(6,1),
    email_aht_min         NUMBER(6,2),
    agents_per_did        NUMBER,
    needs_analytics       BOOLEAN,
    needs_agent_assist    BOOLEAN,
    needs_forecasting     BOOLEAN,
    needs_evaluations     BOOLEAN,
    needs_screen_recording BOOLEAN,
    needs_self_service    BOOLEAN,
    source_type           STRING,
    source_note           STRING
);

INSERT INTO SCENARIOS
SELECT column1, column2, column3, 168, 0.30, 0.80, 0.70, 0.20, 0.10, 6, 1, 0.90, 10, 2, 20, 8, 10,
       TRUE, TRUE, TRUE, TRUE, FALSE, FALSE,
       'DEFAULT', 'Working assumptions agreed with project owner 2026-10-23; editable'
FROM VALUES ('SMALL','< 500 agents',250), ('MEDIUM','500-999 agents',800), ('LARGE','1,000+ agents',2000);

-- ---------------------------------------------------------------
-- BENCHMARK_DEFAULTS: public reference points the agent may cite
-- ---------------------------------------------------------------
CREATE OR REPLACE TABLE BENCHMARK_DEFAULTS (
    metric       STRING,
    value        STRING,
    source_type  STRING,   -- PUBLIC_VENDOR | WORKING_ASSUMPTION
    source_name  STRING,
    source_url   STRING,
    note         STRING
);

INSERT INTO BENCHMARK_DEFAULTS VALUES
('platform_cost_reduction_quote','50% reduction in platform costs','PUBLIC_VENDOR','Flybuys customer quote, AWS pricing page','https://aws.amazon.com/products/connect/customer/pricing/','Vendor-published testimonial; cite as anecdotal'),
('tool_consolidation_quote','Unlimited AI price replaces 3P WFM and QM tools at lower cost','PUBLIC_VENDOR','Cochlear customer quote, AWS pricing page','https://aws.amazon.com/products/connect/customer/pricing/','Vendor-published testimonial; cite as anecdotal'),
('roi_study','See Forrester TEI study','PUBLIC_VENDOR','Forrester TEI of Amazon Connect (commissioned by AWS)','https://d1.awsstatic.com/onedam/marketing-channels/website/aws/en_US/product-categories/contact-center/approved/images/Forrester_TEI_The_Total_Economic_Impact_Of_Amazon_Connect.pdf','Headline figures not yet extracted; do not quote numbers'),
('basic_positioning','AWS describes Customer Basic as for customers who might still be on it / not ready for AI','PUBLIC_VENDOR','AWS pricing appendix','https://aws.amazon.com/products/connect/customer/pricing/appendix/',NULL),
('agent_labor_share','Agent labor is typically the majority of contact center cost (often cited 60-70%)','WORKING_ASSUMPTION','Industry rule of thumb; no specific source captured',NULL,'Shown as context only; excluded from platform TCO'),
('shrinkage_pct','30%','WORKING_ASSUMPTION','Project default',NULL,'Editable'),
('occupancy_pct','80%','WORKING_ASSUMPTION','Project default',NULL,'Editable'),
('voice_aht_min','6','WORKING_ASSUMPTION','Project default',NULL,'Editable');
