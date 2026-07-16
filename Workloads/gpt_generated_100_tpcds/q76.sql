WITH catalog AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         cs.cs_net_profit AS net_profit,
         cs.cs_ext_ship_cost AS ship_cost,
         cs.cs_ext_discount_amt AS discount_amt,
         c.c_customer_id AS customer_id,
         'catalog' AS channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
),
web AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         ws.ws_net_profit AS net_profit,
         ws.ws_ext_ship_cost AS ship_cost,
         ws.ws_ext_discount_amt AS discount_amt,
         c.c_customer_id AS customer_id,
         'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
),
combined AS (
  SELECT d_year,
         d_month_seq,
         i_category,
         net_profit,
         ship_cost,
         discount_amt,
         customer_id,
         channel
  FROM catalog
  UNION ALL
  SELECT d_year,
         d_month_seq,
         i_category,
         net_profit,
         ship_cost,
         discount_amt,
         customer_id,
         channel
  FROM web
)
SELECT
  combined.d_year,
  combined.d_month_seq,
  combined.i_category,
  SUM(CASE WHEN combined.channel = 'catalog' THEN combined.net_profit ELSE 0 END) AS catalog_net_profit,
  SUM(CASE WHEN combined.channel = 'web' THEN combined.net_profit ELSE 0 END) AS web_net_profit,
  SUM(combined.net_profit) AS total_net_profit,
  SUM(combined.ship_cost) AS total_ship_cost,
  AVG(combined.discount_amt) AS avg_discount_amount,
  COUNT(DISTINCT combined.customer_id) AS distinct_customers
FROM combined
GROUP BY combined.d_year, combined.d_month_seq, combined.i_category
ORDER BY combined.d_year, combined.d_month_seq, combined.i_category
