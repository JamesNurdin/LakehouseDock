WITH
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_ext_wholesale_cost > 1000
      AND ss_ext_list_price < 3000
      AND ss_quantity > 1
      AND ss_net_profit > 0
  ),
  date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_current_month = 'Y'
      AND d_week_seq IN (1, 2, 3, 4, 5)
  ),
  hd_filtered AS (
    SELECT *
    FROM household_demographics
    WHERE hd_dep_count >= 5
      AND hd_vehicle_count >= 1
  ),
  income_filtered AS (
    SELECT *
    FROM income_band
    WHERE ib_upper_bound <= 5000
      AND ib_lower_bound >= 0
  ),
  inventory_filtered AS (
    SELECT *
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_item_sk IS NOT NULL
  ),
  joined_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      d.d_year,
      d.d_month_seq,
      hd.hd_demo_sk,
      hd.hd_dep_count,
      ib.ib_income_band_sk,
      ib.ib_upper_bound,
      inv.inv_quantity_on_hand
    FROM date_filtered d
    JOIN sampled_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN hd_filtered hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_filtered ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory_filtered inv
      ON inv.inv_date_sk = d.d_date_sk
  ),
  cross_dim AS (
    SELECT d_week_seq
    FROM date_dim
    WHERE d_week_seq < 3
  ),
  computed_set AS (
    SELECT 1 AS flag UNION ALL SELECT 2 AS flag
  ),
  cross_joined AS (
    SELECT cd.d_week_seq, cs.flag
    FROM cross_dim cd
    CROSS JOIN computed_set cs
  ),
  intersect_keys AS (
    SELECT ss_item_sk FROM sampled_sales
    INTERSECT
    SELECT inv_item_sk FROM inventory_filtered
  ),
  full_outer AS (
    SELECT hd.hd_demo_sk,
           ib.ib_income_band_sk,
           hd.hd_dep_count,
           ib.ib_upper_bound
    FROM hd_filtered hd
    FULL OUTER JOIN income_filtered ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  except_keys AS (
    SELECT hd_demo_sk FROM household_demographics
    EXCEPT
    SELECT ss_hdemo_sk FROM store_sales
  ),
  union_cust AS (
    SELECT ss_customer_sk AS cust_key FROM sampled_sales
    UNION
    SELECT ss_customer_sk FROM store_sales WHERE ss_customer_sk IS NOT NULL
  ),
  final_agg AS (
    SELECT
      d_year,
      d_month_seq,
      SUM(ss_ext_sales_price) AS total_sales,
      AVG(ss_net_profit) AS avg_profit,
      COUNT(DISTINCT ss_item_sk) AS distinct_items_sold,
      MIN(ss_ext_sales_price) AS min_sale,
      MAX(ss_ext_sales_price) AS max_sale
    FROM joined_data
    GROUP BY d_year, d_month_seq
  )
SELECT
  f.d_year,
  f.d_month_seq,
  f.total_sales,
  f.avg_profit,
  f.distinct_items_sold,
  f.min_sale,
  f.max_sale,
  (SELECT COUNT(*) FROM intersect_keys) AS intersect_item_count,
  (SELECT COUNT(*) FROM full_outer WHERE hd_demo_sk IS NULL OR ib_income_band_sk IS NULL) AS outer_unmatched_count,
  (SELECT COUNT(*) FROM except_keys) AS except_demo_count,
  (SELECT COUNT(DISTINCT cust_key) FROM union_cust) AS distinct_customer_count,
  (SELECT COUNT(*) FROM cross_joined) AS cross_join_rows
FROM final_agg f
ORDER BY f.total_sales DESC
LIMIT 100
