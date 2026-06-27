WITH sales_union AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_paid AS net_paid,
        CAST('catalog' AS varchar) AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid AS net_paid,
        CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_paid AS net_paid,
        CAST('web' AS varchar) AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(CASE WHEN su.channel = 'store' THEN su.net_paid ELSE 0 END) AS store_sales,
    SUM(CASE WHEN su.channel = 'catalog' THEN su.net_paid ELSE 0 END) AS catalog_sales,
    SUM(CASE WHEN su.channel = 'web' THEN su.net_paid ELSE 0 END) AS web_sales,
    SUM(su.net_paid) AS total_sales
FROM sales_union su
JOIN customer c ON su.customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_sales DESC
LIMIT 20
