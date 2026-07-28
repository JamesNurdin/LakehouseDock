WITH sales_agg AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       s.s_state,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       AVG(ss.ss_net_profit) AS avg_profit,
       COUNT(*) AS txn_count,
       MIN(ss.ss_sold_date_sk) AS first_sold_date_sk,
       MAX(ss.ss_sold_date_sk) AS last_sold_date_sk
   FROM store_sales ss
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   WHERE s.s_state = 'CA'
     AND s.s_city = 'Fairfield'
     AND s.s_market_desc LIKE '%Formal%'
     AND ss.ss_ext_tax > 20
     AND ss.ss_net_profit > 0
   GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state
),
max_sales AS (
   SELECT MAX(total_sales) AS max_total FROM sales_agg
)
SELECT
   sa.s_store_sk,
   sa.s_store_name,
   sa.s_city,
   sa.s_state,
   sa.total_sales,
   sa.avg_profit,
   sa.txn_count,
   sa.first_sold_date_sk,
   sa.last_sold_date_sk,
   RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
   CASE WHEN sa.total_sales = (SELECT max_total FROM max_sales) THEN 1 ELSE 0 END AS is_top_store
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
