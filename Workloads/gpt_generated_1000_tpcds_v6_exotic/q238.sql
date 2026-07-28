WITH joined AS (
  SELECT
    p.p_promo_id,
    d1.d_year AS year,
    cs.cs_ext_sales_price AS catalog_sales,
    ss.ss_ext_sales_price AS store_sales,
    (cs.cs_net_profit + ss.ss_net_profit) AS total_profit,
    cc.cc_name,
    cp.cp_type,
    p.p_discount_active
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d1
    ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN store_sales ss
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d2
    ON ss.ss_sold_date_sk = d2.d_date_sk
  WHERE d1.d_year = 2001
    AND d2.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'CA'
),
agg AS (
  SELECT
    p_promo_id,
    year,
    SUM(catalog_sales) AS sum_catalog_sales,
    SUM(store_sales) AS sum_store_sales,
    SUM(total_profit) AS sum_total_profit,
    COUNT(*) AS txn_count
  FROM joined
  GROUP BY p_promo_id, year
)
SELECT
  p_promo_id,
  year,
  sum_catalog_sales,
  sum_store_sales,
  sum_total_profit,
  txn_count,
  (sum_catalog_sales + sum_store_sales) / NULLIF(txn_count, 0) AS avg_sales_per_txn,
  RANK() OVER (ORDER BY sum_total_profit DESC) AS profit_rank,
  SUM(sum_total_profit) OVER (PARTITION BY year) AS year_total_profit
FROM agg
WHERE sum_total_profit > 10000
ORDER BY profit_rank
LIMIT 100
