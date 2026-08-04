WITH sales_2001 AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_paid,
    CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS spend_category,
    (SELECT COUNT(*) FROM catalog_sales cs_sub WHERE cs_sub.cs_bill_customer_sk = c.c_customer_sk) AS total_orders
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'costume'
  GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year
),
sales_2002 AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_paid,
    CASE WHEN SUM(cs.cs_net_paid) > 15000 THEN 'High' ELSE 'Low' END AS spend_category,
    (SELECT COUNT(*) FROM catalog_sales cs_sub WHERE cs_sub.cs_bill_customer_sk = c.c_customer_sk) AS total_orders
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2002
    AND sm.sm_type = 'AIR'
    AND EXISTS (
          SELECT 1 FROM call_center cc
          WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
            AND cc.cc_name LIKE '%East%'
        )
  GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year
)
SELECT
  cust_sk,
  customer_id,
  year,
  total_paid,
  spend_category,
  total_orders
FROM (
  SELECT
    c_customer_sk AS cust_sk,
    c_customer_id AS customer_id,
    d_year AS year,
    total_paid,
    spend_category,
    total_orders
  FROM sales_2001
  UNION ALL
  SELECT
    c_customer_sk,
    c_customer_id,
    d_year,
    total_paid,
    spend_category,
    total_orders
  FROM sales_2002
) AS combined
ORDER BY total_paid DESC
LIMIT 100
