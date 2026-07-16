WITH profit_by_cc AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_promo_sk) AS distinct_promo_cnt,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_rec_end_date >= DATE '2000-01-01'
    AND cc.cc_tax_percentage > 0.05
    AND cc.cc_sq_ft > 0
    AND cs.cs_net_profit > 0
    AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451100
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state
  HAVING COUNT(*) >= 100
)
SELECT
  cc_id,
  cc_name,
  cc_city,
  cc_state,
  total_net_profit,
  avg_discount,
  distinct_promo_cnt,
  profit_rank
FROM (
  SELECT
    cc_call_center_id AS cc_id,
    cc_name,
    cc_city,
    cc_state,
    total_net_profit,
    avg_discount,
    distinct_promo_cnt,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
  FROM profit_by_cc
) t
WHERE profit_rank <= 10
ORDER BY profit_rank
