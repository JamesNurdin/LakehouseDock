SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0) AS total_quantity,
    r.avg_sentiment,
    r.review_count
FROM items i
LEFT JOIN (
    SELECT ss_item_id, SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_id
) ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN (
    SELECT ws_item_id, SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_id
) ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN (
    SELECT pr_item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
) r ON i.i_item_id = r.pr_item_id
WHERE i.i_category = 'Electronics'
ORDER BY total_quantity DESC
LIMIT 5
