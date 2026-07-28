WITH sales_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_last_name,
    s.s_store_id,
    s.s_state,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.ss_net_paid) AS total_paid,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
    CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE s.s_state = 'CA'
    AND c.c_birth_month = 5
    AND ib.ib_lower_bound >= 30000
  GROUP BY
    c.c_customer_sk,
    c.c_last_name,
    s.s_store_id,
    s.s_state,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
)
SELECT
  sa.c_customer_sk,
  sa.c_last_name,
  sa.s_store_id,
  sa.s_state,
  sa.profit_category,
  sa.total_paid,
  sa.avg_profit,
  sa.distinct_items,
  ROW_NUMBER() OVER (PARTITION BY sa.s_store_id ORDER BY sa.total_paid DESC) AS store_rank
FROM sales_agg sa
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_customer_sk = sa.c_customer_sk
    AND r.r_reason_desc = 'Damaged'
)
ORDER BY sa.total_paid DESC
LIMIT 100
