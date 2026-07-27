WITH customers_2001 AS (
    SELECT c.c_customer_sk, c.c_customer_id
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    cust.c_customer_id,
    d.d_year AS sales_year,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_amount,
    'catalog' AS source
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customers_2001 cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND w.w_warehouse_sq_ft > 800000
GROUP BY cust.c_customer_id, d.d_year

UNION ALL

SELECT
    cust.c_customer_id,
    d.d_year AS sales_year,
    SUM(ss.ss_net_paid_inc_tax) AS total_amount,
    'store' AS source
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customers_2001 cust ON ss.ss_customer_sk = cust.c_customer_sk
WHERE d.d_year = 2001
GROUP BY cust.c_customer_id, d.d_year

ORDER BY sales_year DESC, total_amount DESC
LIMIT 100
