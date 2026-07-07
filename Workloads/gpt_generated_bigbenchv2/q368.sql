WITH store_qty AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_qty AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_sentiment AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           COALESCE(sq.store_quantity, 0) + COALESCE(wq.web_quantity, 0) AS total_quantity,
           rs.avg_sentiment
    FROM items i
    LEFT JOIN store_qty sq ON i.i_item_id = sq.i_item_id
    LEFT JOIN web_qty wq ON i.i_item_id = wq.i_item_id
    LEFT JOIN review_sentiment rs ON i.i_item_id = rs.i_item_id
)
SELECT
    i_category,
    SUM(total_quantity) AS total_quantity_sold,
    AVG(avg_sentiment) AS avg_review_sentiment
FROM item_sales
WHERE total_quantity > 0
GROUP BY i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
