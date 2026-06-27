WITH combined_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    i_item_id,
    i_name,
    i_category_id,
    i_category_name,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS web_quantity,
    SUM(CASE WHEN channel = 'store' THEN revenue ELSE 0 END) AS store_revenue,
    SUM(CASE WHEN channel = 'web' THEN revenue ELSE 0 END) AS web_revenue,
    CASE WHEN SUM(quantity) > 0 THEN SUM(revenue) / SUM(quantity) ELSE 0 END AS avg_price
FROM combined_sales
GROUP BY i_item_id, i_name, i_category_id, i_category_name
ORDER BY total_revenue DESC
LIMIT 10
