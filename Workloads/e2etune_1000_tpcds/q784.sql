WITH store_monthly AS (
  SELECT
    s.s_store_sk,
    s.s_store_name AS store_name,
    s.s_state AS state,
    floor(ss.ss_sold_date_sk / 100) AS month_key,
    i.i_category AS category,
    i.i_class AS class,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_coupon_amt) AS avg_coupon_amt,
    SUM(CASE WHEN hd.hd_vehicle_count >= 2 THEN ss.ss_ext_sales_price ELSE 0 END) AS sales_high_vehicle,
    COUNT(*) AS txn_count
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 20000101 AND 20001231
    AND s.s_state = 'CO'
    AND i.i_current_price > 50
  GROUP BY s.s_store_sk, s.s_store_name, s.s_state, floor(ss.ss_sold_date_sk / 100), i.i_category, i.i_class
)
SELECT
  store_name,
  state,
  month_key,
  category,
  class,
  total_net_profit,
  total_sales,
  avg_coupon_amt,
  (sales_high_vehicle / NULLIF(total_sales, 0)) AS high_vehicle_sales_ratio,
  txn_count,
  RANK() OVER (PARTITION BY store_name, month_key ORDER BY total_net_profit DESC) AS profit_rank_in_store_month
FROM store_monthly
ORDER BY state, store_name, month_key, profit_rank_in_store_month
LIMIT 100
