WITH
    item_ratings AS (
        SELECT
            pr.pr_item_id AS i_item_id,
            AVG(pr.pr_rating) AS avg_item_rating
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS i_item_id,
            ss.ss_quantity AS quantity
        FROM store_sales ss
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id AS i_item_id,
            ws.ws_quantity AS quantity
        FROM web_sales ws
    ),
    combined_sales AS (
        SELECT i_item_id, quantity FROM store_sales_agg
        UNION ALL
        SELECT i_item_id, quantity FROM web_sales_agg
    )
SELECT
    i.i_category_name,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity * i.i_price) AS total_revenue,
    CASE
        WHEN SUM(cs.quantity) = 0 THEN NULL
        ELSE SUM(cs.quantity * ir.avg_item_rating) / SUM(cs.quantity)
    END AS weighted_avg_rating
FROM combined_sales cs
JOIN items i ON cs.i_item_id = i.i_item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
GROUP BY i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
