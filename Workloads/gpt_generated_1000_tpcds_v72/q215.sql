WITH email_customers AS (
  SELECT DISTINCT c.c_customer_sk, c.c_email_address
  FROM customer c
  WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
),
filtered_sales AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_bill_customer_sk,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_order_number,
    i.i_category,
    i.i_category_id,
    d.d_year
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN email_customers ec ON cs.cs_bill_customer_sk = ec.c_customer_sk
  WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
    AND i.i_product_name LIKE '%PRO%'
)
SELECT
  filtered_sales.d_year,
  filtered_sales.i_category,
  concat('Cat_', cast(filtered_sales.i_category_id AS varchar)) AS category_code,
  sum(filtered_sales.cs_net_paid) AS total_net_paid,
  avg(filtered_sales.cs_net_profit) AS avg_net_profit,
  count(DISTINCT filtered_sales.cs_order_number) AS distinct_orders
FROM filtered_sales
GROUP BY
  filtered_sales.d_year,
  filtered_sales.i_category,
  concat('Cat_', cast(filtered_sales.i_category_id AS varchar))
ORDER BY total_net_paid DESC
LIMIT 100
