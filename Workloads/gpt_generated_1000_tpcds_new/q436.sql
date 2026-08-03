WITH sales_ship AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_item_sk,
    ws.ws_ship_mode_sk,
    sm.sm_ship_mode_sk,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.sm_type,
    CONCAT(sm.sm_carrier, '-', sm.sm_type) AS carrier_type,
    CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    CASE WHEN regexp_like(sm.sm_carrier, '[AEIOU]') THEN 1 ELSE 0 END AS carrier_has_vowel
  FROM web_sales ws
  FULL OUTER JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
avg_profit AS (
  SELECT
    sm_ship_mode_sk,
    avg(ws_net_profit) AS avg_profit
  FROM sales_ship
  WHERE ws_net_profit IS NOT NULL
  GROUP BY sm_ship_mode_sk
),
unused_ship_modes AS (
  SELECT sm_ship_mode_sk FROM ship_mode
  EXCEPT
  SELECT DISTINCT ws_ship_mode_sk FROM web_sales
)
SELECT
  ss.sm_ship_mode_id,
  ss.sm_carrier,
  ss.carrier_type,
  COUNT(DISTINCT ss.ws_order_number) AS distinct_orders_cnt,
  SUM(ss.ws_net_profit) AS total_net_profit,
  AVG(ss.ws_quantity) AS avg_quantity,
  CASE
    WHEN SUM(ss.ws_net_profit) > 0 THEN 'PROFITABLE'
    WHEN SUM(ss.ws_net_profit) < 0 THEN 'LOSS'
    ELSE 'BREAKEVEN'
  END AS profit_category,
  regexp_extract(ss.sm_carrier, '^(...)', 1) AS carrier_prefix,
  EXISTS (
    SELECT 1 FROM avg_profit ap
    WHERE ap.sm_ship_mode_sk = ss.sm_ship_mode_sk
      AND ap.avg_profit > 1000
  ) AS high_avg_profit_flag,
  CASE WHEN ss.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM unused_ship_modes) THEN 1 ELSE 0 END AS is_unused
FROM sales_ship ss
WHERE ss.carrier_type LIKE '%Air%'
GROUP BY
  ss.sm_ship_mode_id,
  ss.sm_carrier,
  ss.carrier_type,
  ss.sm_ship_mode_sk
ORDER BY total_net_profit DESC
LIMIT 100
