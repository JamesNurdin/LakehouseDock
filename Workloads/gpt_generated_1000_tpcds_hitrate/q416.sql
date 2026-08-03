WITH sales AS (
  SELECT
    ss.ss_store_sk,
    s.s_store_name,
    s.s_city,
    ss.ss_promo_sk,
    p.p_promo_name,
    p.p_channel_email,
    ss.ss_net_profit,
    CASE WHEN ss.ss_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    CONCAT(s.s_store_name, ' - ', p.p_promo_name) AS store_promo_desc,
    REGEXP_EXTRACT(p.p_promo_name, '(Discount)', 1) AS discount_word,
    ss.ss_net_profit > (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) AS above_avg_profit
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE REGEXP_LIKE(p.p_promo_name, 'Discount')
    AND s.s_store_name LIKE '%Store%'
    AND d.d_year = 2001
),
stores_with_sales AS (
  SELECT DISTINCT ss_store_sk FROM sales
),
stores_with_returns AS (
  SELECT DISTINCT sr_store_sk FROM store_returns
),
stores_without_returns AS (
  SELECT ss_store_sk FROM stores_with_sales
  EXCEPT
  SELECT sr_store_sk FROM stores_with_returns
),
filtered_sales AS (
  SELECT s.*
  FROM sales s
  JOIN stores_without_returns swr ON s.ss_store_sk = swr.ss_store_sk
)
SELECT
  store_promo_desc,
  profit_category,
  COUNT(*) AS txn_count,
  SUM(ss_net_profit) AS total_profit,
  SUM(CASE WHEN above_avg_profit THEN ss_net_profit ELSE 0 END) AS above_avg_profit_sum
FROM filtered_sales
GROUP BY ROLLUP (store_promo_desc, profit_category)
ORDER BY store_promo_desc, profit_category
LIMIT 100
