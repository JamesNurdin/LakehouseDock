WITH sampled_store_sales AS (
  SELECT ss_customer_sk,
         ss_item_sk,
         ss_sold_date_sk,
         ss_net_profit,
         ss_quantity
  FROM store_sales
  TABLESAMPLE BERNOULLI (10)
  WHERE ss_quantity > 0
),
store_customers AS (
  SELECT DISTINCT ss.ss_customer_sk AS customer_sk,
         ss.ss_item_sk,
         ss.ss_sold_date_sk,
         CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
         d.d_date,
         latest.last_sold_date
  FROM sampled_store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN LATERAL (
    SELECT MAX(d2.d_date) AS last_sold_date
    FROM date_dim d2
    WHERE d2.d_date_sk = ss.ss_sold_date_sk
  ) latest ON TRUE
  WHERE i.i_brand_id = 123
    AND ss.ss_item_sk IN (
      SELECT i2.i_item_sk
      FROM item i2
      WHERE i2.i_category = 'Furniture'
    )
),
web_customers AS (
  SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2002
    AND ws.ws_quantity > 0
)
SELECT sc.customer_sk,
       sc.profit_flag,
       sc.d_date,
       sc.last_sold_date
FROM store_customers sc
WHERE sc.customer_sk IN (
  SELECT i3.i_item_sk
  FROM item i3
  WHERE i3.i_color = 'Red'
) -- example IN sub‑query on a different table
EXCEPT
SELECT wc.customer_sk,
       CAST(NULL AS varchar) AS profit_flag,
       CAST(NULL AS date) AS d_date,
       CAST(NULL AS date) AS last_sold_date
FROM web_customers wc
ORDER BY d_date DESC NULLS LAST
LIMIT 100
