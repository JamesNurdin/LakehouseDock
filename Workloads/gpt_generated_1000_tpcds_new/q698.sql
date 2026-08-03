/*
  Goal: Identify the most profitable call centers in California, ranked by total catalog sales profit,
  after sampling and filtering both catalogs and call‑center data, using aggregations, unions,
  set subtraction, lateral calculations, and a correlated existence check.
*/
WITH
  -- Pre‑aggregate catalog sales per call center (sampled 10% of rows)
  cs_agg AS (
    SELECT
      cs_call_center_sk,
      SUM(cs_net_profit)               AS total_profit,
      COUNT(*)                         AS sales_cnt,
      AVG(cs_list_price)               AS avg_list_price
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_list_price > 100
      AND cs_ext_wholesale_cost < 1000
      AND cs_quantity >= 1
      AND cs_net_paid_inc_tax > 0
    GROUP BY cs_call_center_sk
  ),
  -- Sampled call‑center rows with several filters (sampled 20%)
  cc_filtered AS (
    SELECT *
    FROM call_center
    TABLESAMPLE BERNOULLI (20)
    WHERE cc_gmt_offset BETWEEN -5 AND 5
      AND cc_tax_percentage < 10
      AND cc_state = 'CA'
      AND cc_mkt_id IN (1, 2, 3, 4)
      AND cc_employees > 50
  ),
  -- Union of two key sets: high‑employee call centers and high‑profit sales centers
  union_set AS (
    SELECT cc_call_center_sk FROM cc_filtered WHERE cc_employees > 200
    UNION
    SELECT cs_call_center_sk FROM cs_agg WHERE total_profit > 5000
  ),
  -- Subtract call‑centers that did NOT survive the cc_filtered criteria
  except_set AS (
    SELECT cc_call_center_sk FROM call_center
    EXCEPT
    SELECT cc_call_center_sk FROM cc_filtered
  )
SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  cs_agg.total_profit,
  cs_agg.sales_cnt,
  cc.cc_gmt_offset,
  pc.profit_category,
  RANK() OVER (PARTITION BY cc.cc_state ORDER BY cs_agg.total_profit DESC) AS rank_val
FROM cc_filtered AS cc
JOIN cs_agg
  ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN union_set us
  ON us.cc_call_center_sk = cc.cc_call_center_sk
LEFT JOIN except_set es
  ON es.cc_call_center_sk = cc.cc_call_center_sk
CROSS JOIN LATERAL (
  SELECT CASE
           WHEN cs_agg.total_profit > 10000 THEN 'HIGH'
           WHEN cs_agg.total_profit > 5000  THEN 'MEDIUM'
           ELSE 'LOW'
         END AS profit_category
) AS pc
WHERE es.cc_call_center_sk IS NULL
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
          AND cs2.cs_net_profit > 0
      )
  AND cc.cc_division_name IS NOT NULL
  AND cc.cc_company_name LIKE '%Inc%'
ORDER BY cs_agg.total_profit DESC
LIMIT 100
