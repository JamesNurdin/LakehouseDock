WITH cs_agg AS (
  SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    w.w_warehouse_name AS warehouse_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_indicator,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
    (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS avg_sales_all,
    sm.sm_ship_mode_sk AS ship_mode_sk
  FROM catalog_sales cs
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450810 AND 2450890
    AND sm.sm_type IS NOT NULL
  GROUP BY sm.sm_ship_mode_id, w.w_warehouse_name, sm.sm_ship_mode_sk
),
ws_agg AS (
  SELECT
    sm.sm_ship_mode_id AS ship_mode_id,
    w.w_warehouse_name AS warehouse_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_indicator,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
    (SELECT AVG(ws2.ws_ext_sales_price) FROM web_sales ws2) AS avg_sales_all,
    sm.sm_ship_mode_sk AS ship_mode_sk
  FROM web_sales ws
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450810 AND 2450890
    AND ws.ws_net_profit IS NOT NULL
  GROUP BY sm.sm_ship_mode_id, w.w_warehouse_name, sm.sm_ship_mode_sk
)
SELECT DISTINCT
  ship_mode_id,
  warehouse_name,
  total_sales,
  total_profit,
  profit_indicator,
  sales_rank,
  avg_sales_all
FROM (
  SELECT * FROM cs_agg
  UNION ALL
  SELECT * FROM ws_agg
) combined
WHERE ship_mode_sk NOT IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'EXPRESS')
ORDER BY total_sales DESC, ship_mode_id
LIMIT 100
