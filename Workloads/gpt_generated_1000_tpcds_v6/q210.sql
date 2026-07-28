WITH store_sales_agg AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        SUM(ss.ss_net_paid) AS total_sales,
        CASE WHEN SUM(ss.ss_net_paid) > 1000 THEN 'high' ELSE 'low' END AS sales_category,
        s.s_store_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_id, d.d_date, s.s_store_name
),
web_sales_agg AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        SUM(ws.ws_net_paid) AS total_sales,
        CASE WHEN SUM(ws.ws_net_paid) > 1000 THEN 'high' ELSE 'low' END AS sales_category,
        CAST(NULL AS varchar) AS s_store_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_id, d.d_date
)
SELECT
    cust_id,
    sales_date,
    total_sales,
    sales_category,
    store_name,
    ROW_NUMBER() OVER (PARTITION BY sales_category ORDER BY total_sales DESC) AS category_rank
FROM (
    SELECT
        c_customer_id AS cust_id,
        d_date AS sales_date,
        total_sales,
        sales_category,
        s_store_name AS store_name
    FROM store_sales_agg
    UNION ALL
    SELECT
        c_customer_id AS cust_id,
        d_date AS sales_date,
        total_sales,
        sales_category,
        s_store_name AS store_name
    FROM web_sales_agg
) combined
ORDER BY total_sales DESC
LIMIT 100
