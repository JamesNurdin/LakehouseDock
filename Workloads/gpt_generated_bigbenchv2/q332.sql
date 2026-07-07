WITH unified_sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    us.category_id,
    us.category_name,
    SUM(us.quantity) AS total_quantity,
    SUM(us.quantity * us.price) AS total_revenue,
    SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN us.channel = 'store' THEN us.quantity * us.price ELSE 0 END) AS store_revenue,
    SUM(CASE WHEN us.channel = 'web' THEN us.quantity ELSE 0 END) AS web_quantity,
    SUM(CASE WHEN us.channel = 'web' THEN us.quantity * us.price ELSE 0 END) AS web_revenue
FROM unified_sales us
GROUP BY us.category_id, us.category_name
ORDER BY total_revenue DESC
LIMIT 10
