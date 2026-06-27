WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
combined AS (
    SELECT i_category_id, i_category_name, quantity, revenue, customer_id
    FROM store_agg
    UNION ALL
    SELECT i_category_id, i_category_name, quantity, revenue, customer_id
    FROM web_agg
)
SELECT
    i_category_id,
    i_category_name,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    AVG(revenue / NULLIF(quantity, 0)) AS avg_price_per_item
FROM combined
GROUP BY i_category_id, i_category_name
ORDER BY total_revenue DESC
LIMIT 10
