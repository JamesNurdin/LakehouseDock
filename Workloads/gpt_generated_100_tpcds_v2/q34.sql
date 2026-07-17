/*
Goal: Calculate total net paid per customer for store and catalog channels in the year 2001 by combining store_sales and catalog_sales using UNION ALL.
*/
WITH store_sales_2001 AS (
    SELECT
        c.c_customer_sk,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_sk
),
catalog_sales_2001 AS (
    SELECT
        c.c_customer_sk,
        'catalog' AS sales_channel,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_sk
)
SELECT
    c_customer_sk,
    sales_channel,
    total_net_paid
FROM store_sales_2001
UNION ALL
SELECT
    c_customer_sk,
    sales_channel,
    total_net_paid
FROM catalog_sales_2001
ORDER BY c_customer_sk, sales_channel
