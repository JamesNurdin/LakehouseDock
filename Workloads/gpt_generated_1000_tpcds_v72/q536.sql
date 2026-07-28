WITH sales_a AS (
   SELECT
      ca.ca_state AS state,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
   FROM store_sales ss
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
   GROUP BY ca.ca_state
),
sales_b AS (
   SELECT
      ca.ca_state AS state,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 20000 THEN 'MEDIUM' ELSE 'LOW' END AS profit_category
   FROM store_sales ss
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ss.ss_list_price > 100
   GROUP BY ca.ca_state
),
combined AS (
   SELECT * FROM sales_a
   UNION ALL
   SELECT * FROM sales_b
)
SELECT
   state,
   total_sales,
   total_profit,
   profit_category,
   ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_profit DESC) AS profit_rank
FROM combined
ORDER BY total_profit DESC, state
LIMIT 100
