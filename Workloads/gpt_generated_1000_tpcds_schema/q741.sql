WITH sales_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
),
ship_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
)
SELECT
    ic.c_customer_sk,
    ic.c_first_name,
    ic.c_last_name,
    (
        SELECT SUM(cs_inner.cs_net_paid)
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_bill_customer_sk = ic.c_customer_sk
    ) AS total_spent,
    CASE
        WHEN (
            SELECT SUM(cs_inner.cs_net_paid)
            FROM catalog_sales cs_inner
            WHERE cs_inner.cs_bill_customer_sk = ic.c_customer_sk
        ) > 10000 THEN 'High'
        ELSE 'Medium'
    END AS spend_category
FROM (
    SELECT * FROM sales_customers
    INTERSECT
    SELECT * FROM ship_customers
) AS ic
ORDER BY total_spent DESC
LIMIT 100
