WITH purchases AS (
    SELECT DISTINCT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.cs_ext_sales_price AS amount,
        'sale' AS activity_type
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
),
returns AS (
    SELECT DISTINCT
        sr.sr_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        -sr.sr_return_amt AS amount,
        'return' AS activity_type
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
)
SELECT
    combined.customer_sk,
    combined.c_first_name,
    combined.c_last_name,
    SUM(combined.amount) AS net_amount,
    SUM(CASE WHEN combined.activity_type = 'sale' THEN combined.amount ELSE 0 END) AS total_sales,
    -SUM(CASE WHEN combined.activity_type = 'return' THEN combined.amount ELSE 0 END) AS total_returns,
    COUNT(DISTINCT combined.activity_type) AS activity_types
FROM (
    SELECT * FROM purchases
    UNION ALL
    SELECT * FROM returns
) AS combined
GROUP BY combined.customer_sk, combined.c_first_name, combined.c_last_name
ORDER BY net_amount DESC
LIMIT 100
