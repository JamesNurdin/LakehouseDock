WITH item_sales AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    isales.total_quantity,
    isales.total_revenue,
    iratings.avg_rating,
    isales.distinct_customers
FROM items i
JOIN item_sales isales
    ON isales.i_item_id = i.i_item_id
LEFT JOIN item_ratings iratings
    ON iratings.i_item_id = i.i_item_id
ORDER BY isales.total_revenue DESC
LIMIT 10
