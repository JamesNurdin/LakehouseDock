/* Goal: Combine high‑value sales and high‑value returns per customer to see the combined financial impact, and list the top 100 records. */
WITH sales AS (
  SELECT
    c.c_customer_id AS customer_id,
    'sale' AS activity,
    SUM(cs.cs_ext_sales_price) AS total_amount
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE cs.cs_coupon_amt > 1000
  GROUP BY c.c_customer_id
),
returns AS (
  SELECT
    c.c_customer_id AS customer_id,
    'return' AS activity,
    SUM(cr.cr_return_amount) AS total_amount
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE cr.cr_store_credit > 100
  GROUP BY c.c_customer_id
)
SELECT s.customer_id,
       s.activity,
       s.total_amount
FROM sales s
UNION ALL
SELECT r.customer_id,
       r.activity,
       r.total_amount
FROM returns r
ORDER BY total_amount DESC
LIMIT 100
