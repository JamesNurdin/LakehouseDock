WITH
  agg_a AS (
    SELECT
      sm.sm_carrier AS carrier,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier IN ('LATVIAN', 'GREAT EASTERN')
    GROUP BY sm.sm_carrier
  ),
  sub_a AS (
    SELECT
      carrier,
      total_sales,
      total_profit,
      CASE WHEN total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_status,
      ROW_NUMBER() OVER (PARTITION BY carrier ORDER BY total_sales DESC) AS sales_rank
    FROM agg_a
  ),
  agg_b AS (
    SELECT
      sm.sm_carrier AS carrier,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'GERMA'
      AND ws.ws_list_price > 100
    GROUP BY sm.sm_carrier
  ),
  sub_b AS (
    SELECT
      carrier,
      total_sales,
      total_profit,
      CASE WHEN total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_status,
      ROW_NUMBER() OVER (PARTITION BY carrier ORDER BY total_sales DESC) AS sales_rank
    FROM agg_b
  )
SELECT DISTINCT
  carrier,
  total_sales,
  total_profit,
  profit_status,
  sales_rank
FROM (
  SELECT * FROM sub_a
  UNION ALL
  SELECT * FROM sub_b
) combined
ORDER BY carrier, sales_rank
LIMIT 100
