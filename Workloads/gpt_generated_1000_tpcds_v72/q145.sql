WITH store_agg AS (
  SELECT
    i.i_category AS category,
    'store' AS source,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_upper_bound >= 80000
    AND ss.ss_sold_date_sk BETWEEN 2450905 AND 2451452
  GROUP BY i.i_category
),
catalog_agg AS (
  SELECT
    i.i_category AS category,
    'catalog' AS source,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_lower_bound >= 60000
    AND cs.cs_sold_date_sk BETWEEN 2450905 AND 2451452
  GROUP BY i.i_category
)
SELECT
  category,
  source,
  total_net_paid,
  transaction_cnt
FROM store_agg
UNION ALL
SELECT
  category,
  source,
  total_net_paid,
  transaction_cnt
FROM catalog_agg
ORDER BY category, source
