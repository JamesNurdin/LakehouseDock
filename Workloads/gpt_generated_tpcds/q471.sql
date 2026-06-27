WITH store_sales_profit AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    d.d_year AS year,
    ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
),
web_sales_profit AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    d.d_year AS year,
    ws.ws_net_profit AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
catalog_sales_profit AS (
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    d.d_year AS year,
    cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
),
combined_sales AS (
  SELECT customer_sk, year, net_profit FROM store_sales_profit
  UNION ALL
  SELECT customer_sk, year, net_profit FROM web_sales_profit
  UNION ALL
  SELECT customer_sk, year, net_profit FROM catalog_sales_profit
)
SELECT
  c.c_customer_id,
  combined.year,
  SUM(combined.net_profit) AS total_net_profit
FROM combined_sales combined
JOIN customer c ON combined.customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id, combined.year
ORDER BY total_net_profit DESC
LIMIT 10
