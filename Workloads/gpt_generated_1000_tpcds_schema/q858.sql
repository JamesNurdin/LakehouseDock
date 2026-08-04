WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1210
),
intersect_customers AS (
    SELECT c.c_customer_id,
           CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN recent_dates rd
      ON cs.cs_sold_date_sk = rd.d_date_sk
    INTERSECT
    SELECT c.c_customer_id,
           CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN recent_dates rd
      ON ws.ws_sold_date_sk = rd.d_date_sk
)
SELECT ic.c_customer_id,
       ic.purchase_type
FROM intersect_customers ic
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN customer c2
      ON sr.sr_customer_sk = c2.c_customer_sk
    WHERE c2.c_customer_id = ic.c_customer_id
)
ORDER BY ic.c_customer_id
