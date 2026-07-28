WITH
  sales_a AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      CASE
        WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High'
        ELSE 'Low'
      END AS profit_category
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_manager = 'Franklin Mcclure'
      AND ss.ss_quantity > 1
    GROUP BY s.s_store_id, s.s_store_name
  ),
  sales_b AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      CASE
        WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High'
        ELSE 'Low'
      END AS profit_category
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_manager = 'Brian Norris'
      AND ss.ss_quantity > 5
    GROUP BY s.s_store_id, s.s_store_name
  )
SELECT
  u.s_store_id,
  u.s_store_name,
  u.total_sales,
  u.profit_category
FROM (
  SELECT s_store_id, s_store_name, total_sales, profit_category FROM sales_a
  UNION ALL
  SELECT s_store_id, s_store_name, total_sales, profit_category FROM sales_b
) AS u
ORDER BY u.total_sales DESC
LIMIT 100
