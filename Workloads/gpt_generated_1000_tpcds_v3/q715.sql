WITH catalog_sales_agg AS (
    SELECT
        c.c_customer_id AS c_customer_id,
        cp.cp_department AS cp_department,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE t.t_am_pm = 'PM'
      AND cp.cp_department IN ('Electronics', 'Books')
    GROUP BY c.c_customer_id, cp.cp_department
),
web_sales_agg AS (
    SELECT
        c.c_customer_id AS c_customer_id,
        'Web' AS cp_department,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE t.t_am_pm = 'PM'
    GROUP BY c.c_customer_id
),
combined AS (
    SELECT
        c_customer_id,
        cp_department,
        total_net_paid,
        total_quantity,
        sales_cnt,
        sales_channel
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        c_customer_id,
        cp_department,
        total_net_paid,
        total_quantity,
        sales_cnt,
        sales_channel
    FROM web_sales_agg
)
SELECT
    c_customer_id,
    cp_department,
    total_net_paid,
    total_quantity,
    sales_cnt,
    sales_channel,
    ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_net_paid DESC) AS channel_rank
FROM combined
ORDER BY total_net_paid DESC
LIMIT 100
