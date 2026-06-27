WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales ws
),
item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(cs.quantity) AS total_quantity,
        SUM(cs.quantity * i.i_price) AS total_revenue,
        AVG(ir.avg_rating) AS avg_item_rating,
        COUNT(DISTINCT cs.channel) AS channels_sold_in
    FROM combined_sales cs
    JOIN items i
        ON cs.item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    i_category_id,
    i_category_name,
    total_quantity,
    total_revenue,
    avg_item_rating,
    channels_sold_in
FROM sales_by_category
ORDER BY total_revenue DESC
LIMIT 20
