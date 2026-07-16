WITH sales_aggregated AS (
  SELECT ss_sold_date_sk AS sales_date_sk,
         ss_customer_sk AS customer_sk,
         ss_net_profit AS profit,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk AS sales_date_sk,
         cs_bill_customer_sk AS customer_sk,
         cs_net_profit AS profit,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk AS sales_date_sk,
         ws_bill_customer_sk AS customer_sk,
         ws_net_profit AS profit,
         'web' AS channel
  FROM web_sales
),
customer_sales AS (
  SELECT
    d.d_year AS d_year,
    c.c_customer_sk,
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    COALESCE(SUM(s.profit), 0) AS total_profit,
    COUNT(DISTINCT s.channel) AS channels_used,
    SUM(CASE WHEN s.channel = 'store' THEN s.profit ELSE 0 END) AS store_profit,
    SUM(CASE WHEN s.channel = 'catalog' THEN s.profit ELSE 0 END) AS catalog_profit,
    SUM(CASE WHEN s.channel = 'web' THEN s.profit ELSE 0 END) AS web_profit
  FROM sales_aggregated s
  LEFT JOIN date_dim d ON s.sales_date_sk = d.d_date_sk
  LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
  WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
    AND (c.c_birth_year BETWEEN 1950 AND 1990 OR c.c_birth_year IS NULL)
    AND d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
customer_profit_details AS (
  SELECT
    cs.d_year,
    cs.c_customer_sk,
    cs.c_customer_id,
    cs.full_name,
    cs.total_profit,
    cs.channels_used,
    cs.store_profit,
    cs.catalog_profit,
    cs.web_profit,
    ROUND(
      (SELECT AVG(s2.profit)
         FROM sales_aggregated s2
         WHERE s2.customer_sk = cs.c_customer_sk
      ), 2) AS avg_profit_per_item,
    (SELECT MAX(s3.profit)
       FROM sales_aggregated s3
       WHERE s3.customer_sk = cs.c_customer_sk) AS max_single_profit,
    CASE
      WHEN cs.total_profit > 100000 THEN 'HIGH'
      WHEN cs.total_profit > 50000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_profit DESC) AS profit_rank
  FROM customer_sales cs
),
final_result AS (
  SELECT
    d_year,
    c_customer_id,
    full_name,
    total_profit,
    avg_profit_per_item,
    max_single_profit,
    profit_category,
    profit_rank,
    COALESCE(channels_used, 0) AS channels_used,
    CONCAT('Year ', CAST(d_year AS VARCHAR), ': ', profit_category) AS summary_label
  FROM customer_profit_details
  WHERE profit_rank <= 10
)
SELECT *
FROM final_result
WHERE (profit_category = 'HIGH' OR profit_category = 'MEDIUM')
  AND (full_name IS NOT NULL)
ORDER BY d_year DESC, profit_rank
