WITH cs_agg AS (
   SELECT
      cs_ship_mode_sk,
      SUM(cs_net_paid_inc_tax) AS cs_total_paid,
      COUNT(*) AS cs_order_cnt,
      SUM(cs_net_profit) AS cs_total_profit
   FROM catalog_sales
   GROUP BY cs_ship_mode_sk
),
ws_agg AS (
   SELECT
      ws_ship_mode_sk,
      SUM(ws_net_paid_inc_tax) AS ws_total_paid,
      COUNT(*) AS ws_order_cnt
   FROM web_sales
   GROUP BY ws_ship_mode_sk
)
SELECT
   sm.sm_ship_mode_id,
   sm.sm_code,
   sm.sm_contract,
   CONCAT(sm.sm_ship_mode_id, '-', sm.sm_code) AS full_mode,
   CASE WHEN cs_agg.cs_total_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
   cs_agg.cs_total_paid,
   ws_agg.ws_total_paid,
   ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY cs_agg.cs_total_paid DESC NULLS LAST) AS rn,
   (
      SELECT COUNT(*)
      FROM catalog_sales cs2
      WHERE cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk
        AND cs2.cs_net_paid_inc_tax > COALESCE(cs_agg.cs_total_paid, 0)
   ) AS higher_sales_cnt
FROM ship_mode sm
RIGHT OUTER JOIN cs_agg
   ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ws_agg
   ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE regexp_like(sm.sm_contract, '^A')
  AND sm.sm_code LIKE 'A%'
ORDER BY ws_agg.ws_total_paid DESC, sm.sm_code
