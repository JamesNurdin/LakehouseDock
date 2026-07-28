WITH
sales_by_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_salutation,
        c.c_email_address,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_catalog_page_sk IN (136, 239)
      AND c.c_salutation = 'Mr.'
    GROUP BY ROLLUP (c.c_customer_sk, c.c_salutation, c.c_email_address)
),

sales_by_salutation AS (
    SELECT
        NULL AS c_customer_sk,
        c.c_salutation,
        NULL AS c_email_address,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'Very High' ELSE 'Medium' END AS sales_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_catalog_page_sk IN (136, 239)
      AND c.c_salutation = 'Mr.'
    GROUP BY ROLLUP (c.c_salutation)
),

top_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_ship_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 2000
)
SELECT
    u.sales_category,
    AVG(u.total_sales) AS avg_total_sales,
    SUM(u.total_profit) AS sum_total_profit
FROM (
    SELECT * FROM sales_by_customer
    UNION ALL
    SELECT * FROM sales_by_salutation
) u
WHERE NOT EXISTS (
    SELECT 1 FROM top_customers tc
    WHERE tc.c_customer_sk = u.c_customer_sk
)
GROUP BY GROUPING SETS ((u.sales_category), ())
ORDER BY u.sales_category NULLS LAST
LIMIT 100
