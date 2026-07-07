WITH sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_price,
           COALESCE(ss.ss_total, 0) + COALESCE(ws.ws_total, 0) AS total_quantity_sold
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id,
               SUM(ss_quantity) AS ss_total
        FROM store_sales
        GROUP BY ss_item_id
    ) ss ON i.i_item_id = ss.ss_item_id
    LEFT JOIN (
        SELECT ws_item_id,
               SUM(ws_quantity) AS ws_total
        FROM web_sales
        GROUP BY ws_item_id
    ) ws ON i.i_item_id = ws.ws_item_id
),
reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.i_price,
       s.total_quantity_sold,
       r.avg_sentiment,
       r.review_count
FROM sales s
LEFT JOIN reviews r ON s.i_item_id = r.i_item_id
ORDER BY s.total_quantity_sold DESC
LIMIT 20
