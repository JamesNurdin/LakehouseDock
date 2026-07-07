WITH store_stats AS (
    SELECT i.i_category AS category,
           'store' AS channel,
           SUM(ss.ss_quantity * i.i_price) AS revenue,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_stats AS (
    SELECT i.i_category AS category,
           'web' AS channel,
           SUM(ws.ws_quantity * i.i_price) AS revenue,
           SUM(ws.ws_quantity) AS total_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
combined AS (
    SELECT category,
           channel,
           revenue,
           total_quantity,
           distinct_customers
    FROM store_stats
    UNION ALL
    SELECT category,
           channel,
           revenue,
           total_quantity,
           distinct_customers
    FROM web_stats
)
SELECT category,
       channel,
       revenue,
       total_quantity,
       distinct_customers,
       revenue / distinct_customers AS avg_revenue_per_customer
FROM combined
ORDER BY revenue DESC
LIMIT 10
