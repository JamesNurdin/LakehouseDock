WITH sales_per_customer AS (
  SELECT
    c.c_customer_id,
    c.c_customer_sk,
    SUM(cs.cs_net_paid_inc_ship) AS total_paid,
    COUNT(*) AS order_cnt,
    CONCAT('Cust-', SUBSTR(c.c_customer_id, 1, 4)) AS cust_label
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE cs.cs_sales_price > 5.00
  GROUP BY c.c_customer_id, c.c_customer_sk
),
returns_per_customer AS (
  SELECT
    c.c_customer_id,
    c.c_customer_sk,
    SUM(wr.wr_return_amt) AS total_return,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE wr.wr_return_amt > 10.00
  GROUP BY c.c_customer_id, c.c_customer_sk
)
SELECT DISTINCT
  spc.c_customer_id,
  spc.total_paid,
  spc.order_cnt,
  spc.cust_label,
  (SELECT AVG(total_paid) FROM sales_per_customer) AS avg_total_paid,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      JOIN warehouse w ON cs2.cs_warehouse_sk = w.w_warehouse_sk
      WHERE cs2.cs_bill_customer_sk = spc.c_customer_sk
        AND w.w_city LIKE '%Ash%'
    ) THEN 'Ash City'
    ELSE 'Other City'
  END AS city_group
FROM sales_per_customer spc
WHERE REGEXP_LIKE(spc.c_customer_id, '^AAAAAAAA[OH]')
  AND spc.total_paid > (SELECT AVG(total_paid) FROM sales_per_customer)
UNION ALL
SELECT DISTINCT
  rpc.c_customer_id,
  rpc.total_return AS total_paid,
  rpc.return_cnt AS order_cnt,
  CONCAT('Return-', SUBSTR(rpc.c_customer_id, 5, 3)) AS cust_label,
  (SELECT AVG(total_paid) FROM sales_per_customer) AS avg_total_paid,
  'Return Customer' AS city_group
FROM returns_per_customer rpc
WHERE REGEXP_LIKE(rpc.c_customer_id, 'HEG')
  AND rpc.total_return > 50
LIMIT 100
