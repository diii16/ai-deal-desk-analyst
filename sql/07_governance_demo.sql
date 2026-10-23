-- 30-second governance demo (Snowsight worksheet). Same data, same tool the agent calls, different role.
-- Run each block and point at: viewing_role, deal_count, and the quoted price fields (null for the rep).

USE ROLE DEALDESK_REP;          -- seller Jordan Lee
CALL CX_TCO.CORE.LIST_DEALS();  -- 3 deals, quoted price and discount hidden (masking policy)

USE ROLE DEALDESK_MANAGER;      -- deal desk manager
CALL CX_TCO.CORE.LIST_DEALS();  -- 6 deals from 3 reps, quoted price and discount visible

-- The policies behind it
DESCRIBE ROW ACCESS POLICY CX_TCO.CORE.DEAL_OWNER_POLICY;
DESCRIBE MASKING POLICY CX_TCO.CORE.DEAL_PRICE_MASK;

USE ROLE ATTENDEE_ROLE;
