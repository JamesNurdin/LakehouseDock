WITH
  ss AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      i.i_category,
      i.i_brand
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit > 0
  ),
  ws AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      ws.ws_order_number AS ticket_number,
      ws.ws_net_profit,
      i.i_category,
      i.i_brand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_profit > 0
  ),
  full_join AS (
    SELECT
      COALESCE(ss.item_sk, ws.item_sk) AS item_sk,
      ss.ss_ticket_number,
      ws.ticket_number,
      ss.ss_net_profit AS ss_profit,
      ws.ws_net_profit AS ws_profit,
      ss.i_category,
      ss.i_brand
    FROM ss
    FULL OUTER JOIN ws ON ss.item_sk = ws.item_sk
  ),
  union_set AS (
    SELECT DISTINCT item_sk, i_category, i_brand
    FROM full_join
    WHERE ss_profit IS NOT NULL
    UNION
    SELECT DISTINCT item_sk, i_category, i_brand
    FROM full_join
    WHERE ws_profit IS NOT NULL
  ),
  except_set AS (
    SELECT item_sk
    FROM union_set
    EXCEPT
    SELECT sr_item_sk
    FROM store_returns
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY e.item_sk) AS rn,
  e.item_sk,
  itm.i_category,
  itm.i_brand
FROM except_set e
LEFT JOIN item itm ON e.item_sk = itm.i_item_sk
ORDER BY rn
LIMIT 100
