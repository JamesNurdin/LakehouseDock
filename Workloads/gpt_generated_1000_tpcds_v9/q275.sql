WITH catalog_agg AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(cs.cs_net_paid) AS sales_amount,
        'catalog' AS channel
    FROM catalog_sales cs
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
    GROUP BY 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
),
web_agg AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(ws.ws_net_paid) AS sales_amount,
        'web' AS channel
    FROM web_sales ws
    INNER JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
    GROUP BY 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
),
combined_sales AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT DISTINCT
    cs.customer_sk,
    cs.customer_id,
    cs.first_name,
    cs.last_name,
    cs.channel,
    cs.sales_amount,
    (
        SELECT COUNT(DISTINCT cs2.cs_order_number)
        FROM catalog_sales cs2
        INNER JOIN date_dim d2
            ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE cs2.cs_bill_customer_sk = cs.customer_sk
          AND d2.d_fy_year = 1915
    ) AS catalog_order_cnt
FROM combined_sales cs
ORDER BY cs.sales_amount DESC
LIMIT 100
