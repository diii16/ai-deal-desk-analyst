-- Phase 2: TCO calculator
-- Built at the Intelligence at Work Hackathon, 2026-10-23.
-- All math is deterministic SQL over PRICE_CATALOG; the LLM never computes prices.

USE SCHEMA CX_TCO.CORE;

-- ---------------------------------------------------------------
-- V_SCENARIO_VOLUMES: derives monthly volumes from the S/M/L assumptions
-- ---------------------------------------------------------------
CREATE OR REPLACE VIEW V_SCENARIO_VOLUMES AS
SELECT
    size_code, size_band, agents,
    paid_hours_per_agent * (1 - shrinkage_pct) * occupancy_pct * 60          AS handle_min_per_agent,
    ROUND(agents * handle_min_per_agent * voice_share_pct / voice_aht_min)    AS voice_calls_per_month,
    voice_aht_min, ivr_queue_min_per_call, inbound_share_pct,
    ROUND(agents * handle_min_per_agent * chat_share_pct * chat_concurrency / chat_min_per_chat) AS chats_per_month,
    messages_per_chat,
    ROUND(agents * handle_min_per_agent * email_share_pct / email_aht_min)    AS emails_per_month,
    0                                                                         AS sms_messages_per_month,
    agents_per_did,
    needs_analytics, needs_agent_assist, needs_forecasting, needs_evaluations,
    needs_screen_recording, needs_self_service,
    source_type, source_note
FROM SCENARIOS;

-- ---------------------------------------------------------------
-- CALC_TCO_LINES: one row per cost line, for both Connect options
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION CALC_TCO_LINES(
    agents NUMBER, voice_calls NUMBER, voice_aht_min FLOAT, ivr_min_per_call FLOAT, inbound_share FLOAT,
    chats NUMBER, messages_per_chat FLOAT, emails NUMBER, sms_messages NUMBER, agents_per_did NUMBER,
    needs_analytics BOOLEAN, needs_agent_assist BOOLEAN, needs_forecasting BOOLEAN,
    needs_evaluations BOOLEAN, needs_screen_recording BOOLEAN, needs_self_service BOOLEAN,
    p_price_version STRING
)
RETURNS TABLE (product STRING, cost_layer STRING, component STRING, channel STRING,
               quantity FLOAT, unit STRING, unit_price FLOAT, monthly_cost FLOAT, note STRING)
AS
$$
WITH p AS (
    SELECT
        MAX(IFF(product='CONNECT_CUSTOMER' AND component='CHANNEL_USAGE' AND channel='VOICE', price::FLOAT, NULL))     AS c_voice,
        MAX(IFF(product='CONNECT_CUSTOMER' AND component='CHANNEL_USAGE' AND channel='CHAT', price::FLOAT, NULL))      AS c_chat,
        MAX(IFF(product='CONNECT_CUSTOMER' AND component='CHANNEL_USAGE' AND channel='MESSAGING', price::FLOAT, NULL)) AS c_msg,
        MAX(IFF(product='CONNECT_CUSTOMER' AND component='CHANNEL_USAGE' AND channel='EMAIL', price::FLOAT, NULL))     AS c_email,
        MAX(IFF(product='CONNECT_BASIC' AND component='CHANNEL_USAGE' AND channel='VOICE', price::FLOAT, NULL))        AS b_voice,
        MAX(IFF(product='CONNECT_BASIC' AND component='CHANNEL_USAGE' AND channel='CHAT', price::FLOAT, NULL))         AS b_chat,
        MAX(IFF(product='CONNECT_BASIC' AND component='CHANNEL_USAGE' AND channel='MESSAGING', price::FLOAT, NULL))    AS b_msg,
        MAX(IFF(product='CONNECT_BASIC' AND component='CHANNEL_USAGE' AND channel='EMAIL', price::FLOAT, NULL))        AS b_email,
        MAX(IFF(product='CONNECT_BASIC' AND component='CONV_ANALYTICS' AND channel='VOICE' AND tier_min = 0, price::FLOAT, NULL)) AS b_ana_v1,
        MAX(IFF(product='CONNECT_BASIC' AND component='CONV_ANALYTICS' AND channel='VOICE' AND tier_min > 0, price::FLOAT, NULL)) AS b_ana_v2,
        MAX(IFF(product='CONNECT_BASIC' AND component='CONV_ANALYTICS' AND channel='VOICE' AND tier_min > 0, tier_min::FLOAT, NULL)) AS b_ana_break,
        MAX(IFF(product='CONNECT_BASIC' AND component='CONV_ANALYTICS' AND channel='CHAT', price::FLOAT, NULL))        AS b_ana_chat,
        MAX(IFF(product='CONNECT_BASIC' AND component='CONV_ANALYTICS' AND channel='MESSAGING', price::FLOAT, NULL))   AS b_ana_msg,
        MAX(IFF(product='CONNECT_BASIC' AND component='AGENT_ASSIST' AND channel='VOICE', price::FLOAT, NULL))         AS b_aa_v,
        MAX(IFF(product='CONNECT_BASIC' AND component='AGENT_ASSIST' AND channel='CHAT', price::FLOAT, NULL))          AS b_aa_chat,
        MAX(IFF(product='CONNECT_BASIC' AND component='AGENT_ASSIST' AND channel='MESSAGING', price::FLOAT, NULL))     AS b_aa_msg,
        MAX(IFF(product='CONNECT_BASIC' AND component='AGENT_ASSIST' AND channel='EMAIL', price::FLOAT, NULL))         AS b_aa_email,
        MAX(IFF(product='CONNECT_BASIC' AND component='SELF_SERVICE' AND channel='VOICE', price::FLOAT, NULL))         AS b_ss_v,
        MAX(IFF(product='CONNECT_BASIC' AND component='SELF_SERVICE' AND channel='CHAT', price::FLOAT, NULL))          AS b_ss_chat,
        MAX(IFF(product='CONNECT_BASIC' AND component='SCREEN_RECORDING', price::FLOAT, NULL))                         AS b_sr,
        MAX(IFF(product='CONNECT_BASIC' AND component='FORECASTING', price::FLOAT, NULL))                              AS b_fc,
        MAX(IFF(product='CONNECT_BASIC' AND component='EVALUATIONS', price::FLOAT, NULL))                              AS b_ev,
        MAX(IFF(product='TELEPHONY_US' AND component='DID_NUMBER', price::FLOAT, NULL))                                AS t_did,
        MAX(IFF(product='TELEPHONY_US' AND component='INBOUND_DID', price::FLOAT, NULL))                               AS t_in,
        MAX(IFF(product='TELEPHONY_US' AND component='OUTBOUND_US', price::FLOAT, NULL))                               AS t_out
    FROM PRICE_CATALOG
    WHERE price_version = p_price_version
),
v AS (
    SELECT
        voice_calls * inbound_share * (voice_aht_min + ivr_min_per_call)  AS inbound_min,
        voice_calls * (1 - inbound_share) * voice_aht_min                 AS outbound_min,
        inbound_min + outbound_min                                        AS voice_min,
        voice_calls * voice_aht_min                                       AS agent_voice_min,
        voice_calls * inbound_share * ivr_min_per_call                    AS ivr_min,
        chats * messages_per_chat                                         AS chat_msgs,
        CEIL(agents / NULLIF(agents_per_did, 0))::FLOAT                   AS dids
),
lines AS (
    -- Telephony (same for both options)
    SELECT prod.product, 'TELEPHONY', 'DID_NUMBER', 'VOICE', v.dids * 30, 'number-days', p.t_did, v.dids * 30 * p.t_did, '1 DID per ' || agents_per_did || ' agents, 30 days'
    FROM p, v, (SELECT 'CONNECT_CUSTOMER' product UNION ALL SELECT 'CONNECT_BASIC') prod
    UNION ALL SELECT prod.product, 'TELEPHONY', 'INBOUND_DID', 'VOICE', v.inbound_min, 'min', p.t_in, v.inbound_min * p.t_in, 'US inbound DID rate'
    FROM p, v, (SELECT 'CONNECT_CUSTOMER' product UNION ALL SELECT 'CONNECT_BASIC') prod
    UNION ALL SELECT prod.product, 'TELEPHONY', 'OUTBOUND_US', 'VOICE', v.outbound_min, 'min', p.t_out, v.outbound_min * p.t_out, 'US outbound rate'
    FROM p, v, (SELECT 'CONNECT_CUSTOMER' product UNION ALL SELECT 'CONNECT_BASIC') prod
    -- Connect Customer: channel rates include all AI capabilities
    UNION ALL SELECT 'CONNECT_CUSTOMER', 'PLATFORM', 'CHANNEL_USAGE', 'VOICE', v.voice_min, 'min', p.c_voice, v.voice_min * p.c_voice, 'Includes IVR/queue time; all AI included' FROM p, v
    UNION ALL SELECT 'CONNECT_CUSTOMER', 'PLATFORM', 'CHANNEL_USAGE', 'CHAT', v.chat_msgs, 'messages', p.c_chat, v.chat_msgs * p.c_chat, 'All AI included' FROM p, v
    UNION ALL SELECT 'CONNECT_CUSTOMER', 'PLATFORM', 'CHANNEL_USAGE', 'MESSAGING', sms_messages::FLOAT, 'messages', p.c_msg, sms_messages * p.c_msg, 'SMS delivery fees excluded' FROM p, v
    UNION ALL SELECT 'CONNECT_CUSTOMER', 'PLATFORM', 'CHANNEL_USAGE', 'EMAIL', emails::FLOAT, 'emails', p.c_email, emails * p.c_email, 'All AI included' FROM p, v
    -- Connect Basic: channel usage
    UNION ALL SELECT 'CONNECT_BASIC', 'PLATFORM', 'CHANNEL_USAGE', 'VOICE', v.voice_min, 'min', p.b_voice, v.voice_min * p.b_voice, 'Includes IVR/queue time' FROM p, v
    UNION ALL SELECT 'CONNECT_BASIC', 'PLATFORM', 'CHANNEL_USAGE', 'CHAT', v.chat_msgs, 'messages', p.b_chat, v.chat_msgs * p.b_chat, NULL FROM p, v
    UNION ALL SELECT 'CONNECT_BASIC', 'PLATFORM', 'CHANNEL_USAGE', 'MESSAGING', sms_messages::FLOAT, 'messages', p.b_msg, sms_messages * p.b_msg, 'SMS delivery fees excluded' FROM p, v
    UNION ALL SELECT 'CONNECT_BASIC', 'PLATFORM', 'CHANNEL_USAGE', 'EMAIL', emails::FLOAT, 'emails', p.b_email, emails * p.b_email, NULL FROM p, v
    -- Connect Basic: AI add-ons needed for capability parity
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'CONV_ANALYTICS', 'VOICE', v.voice_min, 'min', p.b_ana_v1,
        LEAST(v.voice_min, p.b_ana_break) * p.b_ana_v1 + GREATEST(v.voice_min - p.b_ana_break, 0) * p.b_ana_v2, 'Tiered: first 5M min then lower rate'
        FROM p, v WHERE needs_analytics
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'CONV_ANALYTICS', 'CHAT', v.chat_msgs, 'messages', p.b_ana_chat, v.chat_msgs * p.b_ana_chat, NULL FROM p, v WHERE needs_analytics
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'CONV_ANALYTICS', 'MESSAGING', sms_messages::FLOAT, 'messages', p.b_ana_msg, sms_messages * p.b_ana_msg, NULL FROM p, v WHERE needs_analytics
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'AGENT_ASSIST', 'VOICE', v.agent_voice_min, 'min', p.b_aa_v, v.agent_voice_min * p.b_aa_v, 'Agent-connected minutes' FROM p, v WHERE needs_agent_assist
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'AGENT_ASSIST', 'CHAT', v.chat_msgs, 'messages', p.b_aa_chat, v.chat_msgs * p.b_aa_chat, NULL FROM p, v WHERE needs_agent_assist
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'AGENT_ASSIST', 'MESSAGING', sms_messages::FLOAT, 'messages', p.b_aa_msg, sms_messages * p.b_aa_msg, NULL FROM p, v WHERE needs_agent_assist
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'AGENT_ASSIST', 'EMAIL', emails::FLOAT, 'emails', p.b_aa_email, emails * p.b_aa_email, 'Assumes all emails inbound' FROM p, v WHERE needs_agent_assist
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'SELF_SERVICE', 'VOICE', v.ivr_min, 'min', p.b_ss_v, v.ivr_min * p.b_ss_v, 'IVR minutes; Lex charges excluded' FROM p, v WHERE needs_self_service
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'SELF_SERVICE', 'CHAT', v.chat_msgs, 'messages', p.b_ss_chat, v.chat_msgs * p.b_ss_chat, 'Lex charges excluded' FROM p, v WHERE needs_self_service
    UNION ALL SELECT 'CONNECT_BASIC', 'AI_ADDON', 'SCREEN_RECORDING', 'VOICE', v.agent_voice_min, 'min', p.b_sr, v.agent_voice_min * p.b_sr, 'Agent-connected minutes only' FROM p, v WHERE needs_screen_recording
    UNION ALL SELECT 'CONNECT_BASIC', 'PER_AGENT_ADDON', 'FORECASTING', 'ALL', agents::FLOAT, 'agent-months', p.b_fc, agents * p.b_fc, 'Forecasting, capacity planning, scheduling' FROM p, v WHERE needs_forecasting
    UNION ALL SELECT 'CONNECT_BASIC', 'PER_AGENT_ADDON', 'EVALUATIONS', 'ALL', agents::FLOAT, 'agent-months', p.b_ev, agents * p.b_ev, 'Assumes every agent evaluated monthly' FROM p, v WHERE needs_evaluations
)
SELECT * FROM lines
$$;

-- ---------------------------------------------------------------
-- CALC_TCO: agent tool. Returns totals, cost lines, parity gaps, and caveats as JSON.
-- Validated: AWS pricing example 1 (75 agents) reproduces $4,800.90/month exactly.
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CALC_TCO(
    agents NUMBER, voice_calls NUMBER, voice_aht_min FLOAT, ivr_min_per_call FLOAT, inbound_share FLOAT,
    chats NUMBER, messages_per_chat FLOAT, emails NUMBER, sms_messages NUMBER, agents_per_did NUMBER,
    needs_analytics BOOLEAN, needs_agent_assist BOOLEAN, needs_forecasting BOOLEAN,
    needs_evaluations BOOLEAN, needs_screen_recording BOOLEAN, needs_self_service BOOLEAN
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    totals VARIANT;
    lines VARIANT;
    gaps VARIANT;
BEGIN
    CREATE OR REPLACE TEMPORARY TABLE tmp_tco_lines AS
    SELECT * FROM TABLE(CX_TCO.CORE.CALC_TCO_LINES(:agents, :voice_calls, :voice_aht_min, :ivr_min_per_call, :inbound_share,
           :chats, :messages_per_chat, :emails, :sms_messages, :agents_per_did,
           :needs_analytics, :needs_agent_assist, :needs_forecasting, :needs_evaluations,
           :needs_screen_recording, :needs_self_service, 'AWS-CONNECT-2026-10-23'));

    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
               'product', product,
               'monthly_cost', ROUND(m, 2),
               'annual_tco', ROUND(m * 12, 2),
               'cost_per_agent_month', ROUND(m / NULLIF(:agents, 0), 2),
               'cost_per_contact', ROUND(m / NULLIF(:voice_calls + :chats + :emails, 0), 4),
               'platform', ROUND(pl, 2), 'telephony', ROUND(te, 2),
               'ai_addons', ROUND(ai, 2), 'per_agent_addons', ROUND(pa, 2)))
      INTO :totals
      FROM (SELECT product, SUM(monthly_cost) m,
                   SUM(IFF(cost_layer = 'PLATFORM', monthly_cost, 0)) pl,
                   SUM(IFF(cost_layer = 'TELEPHONY', monthly_cost, 0)) te,
                   SUM(IFF(cost_layer = 'AI_ADDON', monthly_cost, 0)) ai,
                   SUM(IFF(cost_layer = 'PER_AGENT_ADDON', monthly_cost, 0)) pa
            FROM tmp_tco_lines GROUP BY product);

    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('product', product, 'layer', cost_layer, 'component', component,
               'channel', channel, 'quantity', ROUND(quantity), 'unit', unit, 'unit_price', unit_price,
               'monthly_cost', ROUND(monthly_cost, 2), 'note', note))
      INTO :lines
      FROM tmp_tco_lines WHERE monthly_cost > 0;

    SELECT ARRAY_AGG(capability_name) INTO :gaps
      FROM CX_TCO.CORE.FEATURE_MAP WHERE product = 'CONNECT_BASIC' AND status = 'NOT_AVAILABLE';

    RETURN OBJECT_CONSTRUCT(
        'price_version', 'AWS-CONNECT-2026-10-23',
        'currency', 'USD', 'region', 'North America (US rates, us-west-2)',
        'source_url', 'https://aws.amazon.com/products/connect/customer/pricing/appendix/',
        'inputs', OBJECT_CONSTRUCT('agents', agents, 'voice_calls', voice_calls, 'voice_aht_min', voice_aht_min,
                     'ivr_min_per_call', ivr_min_per_call, 'inbound_share', inbound_share, 'chats', chats,
                     'messages_per_chat', messages_per_chat, 'emails', emails, 'sms_messages', sms_messages,
                     'agents_per_did', agents_per_did, 'needs_analytics', needs_analytics,
                     'needs_agent_assist', needs_agent_assist, 'needs_forecasting', needs_forecasting,
                     'needs_evaluations', needs_evaluations, 'needs_screen_recording', needs_screen_recording,
                     'needs_self_service', needs_self_service),
        'totals', totals,
        'lines', lines,
        'basic_not_available', gaps,
        'caveats', ARRAY_CONSTRUCT_COMPACT(
            'List prices only; excludes taxes, SMS delivery fees, Lex, Polly and 3P model costs.',
            'Telephony uses US DID inbound/outbound rates from AWS worked examples; toll-free not modeled.',
            'Excludes implementation, migration, admin/training and agent labor.',
            'Connect Customer pricing applies to all channels in an instance; options cannot be mixed.',
            IFF(needs_analytics AND emails > 0, 'Basic has no email analytics; Customer includes it.', NULL)));
END;
$$;

-- ---------------------------------------------------------------
-- GET_DEFAULT_PROFILE: agent tool. DEFAULT demand profile for any agent count.
-- channels: VOICE_ONLY or OMNI (voice + chat + email)
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GET_DEFAULT_PROFILE(agents NUMBER, channels STRING)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Returns a DEFAULT demand profile for any agent count. channels: VOICE_ONLY or OMNI (voice+chat+email).'
AS
$$
DECLARE
    prof VARIANT;
BEGIN
    SELECT OBJECT_CONSTRUCT(
        'agents', :agents,
        'size_band', CASE WHEN :agents < 500 THEN 'SMALL (< 500 agents)' WHEN :agents < 1000 THEN 'MEDIUM (500-999 agents)' ELSE 'LARGE (1,000+ agents)' END,
        'channels', UPPER(:channels),
        'voice_calls', ROUND(:agents * h * IFF(UPPER(:channels) = 'VOICE_ONLY', 1, voice_share_pct) / voice_aht_min),
        'voice_aht_min', voice_aht_min,
        'ivr_min_per_call', ivr_queue_min_per_call,
        'inbound_share', inbound_share_pct,
        'chats', IFF(UPPER(:channels) = 'VOICE_ONLY', 0, ROUND(:agents * h * chat_share_pct * chat_concurrency / chat_min_per_chat)),
        'messages_per_chat', messages_per_chat,
        'emails', IFF(UPPER(:channels) = 'VOICE_ONLY', 0, ROUND(:agents * h * email_share_pct / email_aht_min)),
        'sms_messages', 0,
        'agents_per_did', agents_per_did,
        'source_type', 'DEFAULT',
        'assumptions', OBJECT_CONSTRUCT(
            'paid_hours_per_agent_month', paid_hours_per_agent, 'shrinkage', shrinkage_pct, 'occupancy', occupancy_pct,
            'handle_minutes_per_agent_month', ROUND(h),
            'channel_mix_of_handle_time', IFF(UPPER(:channels) = 'VOICE_ONLY', 'voice 100%', 'voice 70% / chat 20% / email 10%'),
            'chat', 'concurrency 2, 10 min per chat, 20 messages per chat (incl. bot/AI messages)',
            'email_aht_min', email_aht_min),
        'note', 'Working assumptions, not benchmarks. Replace any value the seller knows. Forrester TEI composite uses 10-min AHT, 75% voice, 10 messages per chat.')
      INTO :prof
      FROM (SELECT *, paid_hours_per_agent * (1 - shrinkage_pct) * occupancy_pct * 60 AS h
            FROM CX_TCO.CORE.SCENARIOS WHERE size_code = 'SMALL');
    RETURN prof;
END;
$$;
