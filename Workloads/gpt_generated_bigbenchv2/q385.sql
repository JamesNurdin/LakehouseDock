WITH unified_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_item_id,
        i.i_category,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    us.i_category,
    SUM(us.quantity) AS total_quantity_sold,
    SUM(us.quantity * us.price) AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_sentiment
FROM unified_sales us
LEFT JOIN product_reviews pr ON pr.pr_item_id = us.i_item_id
GROUP BY us.i_category
ORDER BY total_revenue DESC
LIMIT 10
