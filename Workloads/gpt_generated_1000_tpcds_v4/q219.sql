WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count,
        MAX(cs_ext_wholesale_cost) AS max_wholesale_cost
    FROM catalog_sales
    WHERE cs_wholesale_cost > 20.00                -- filter 1: only relatively high wholesale cost items
      AND cs_promo_sk IN (878, 1023)                -- filter 2: focus on two promo campaigns
    GROUP BY cs_call_center_sk
    HAVING SUM(cs_ext_sales_price) > 100000        -- filter 3: keep only high‑volume call centers
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cs.total_sales,
    cs.total_profit,
    cs.avg_discount,
    cs.order_count,
    cs.max_wholesale_cost
FROM call_center cc
JOIN cs_agg cs
  ON cc.cc_call_center_sk = cs.cs_call_center_sk
WHERE cc.cc_state = 'CA'                               -- filter 4: restrict to California
  AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00          -- filter 5: specific GMT offset range
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
          AND cs2.cs_ext_wholesale_cost = cs.max_wholesale_cost
    )                                                   -- subquery: ensure the max wholesale cost actually occurs
ORDER BY cs.total_sales DESC
LIMIT 100
