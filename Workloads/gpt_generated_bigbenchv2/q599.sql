WITH item_sales AS (
    SELECT items.i_item_id,
           SUM(store_sales.ss_quantity) AS total_quantity_store
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY items.i_item_id
),
web_item_sales AS (
    SELECT items.i_item_id,
           SUM(web_sales.ws_quantity) AS total_quantity_web
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY items.i_item_id
),
combined_sales AS (
    SELECT COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
           COALESCE(s.total_quantity_store, 0) + COALESCE(w.total_quantity_web, 0) AS total_quantity
    FROM item_sales s
    FULL OUTER JOIN web_item_sales w ON s.i_item_id = w.i_item_id
),
item_sentiment AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category AS category,
       SUM(cs.total_quantity * isent.avg_sentiment) / SUM(cs.total_quantity) AS weighted_avg_sentiment,
       SUM(cs.total_quantity) AS total_quantity_sold
FROM combined_sales cs
JOIN items i ON cs.i_item_id = i.i_item_id
JOIN item_sentiment isent ON i.i_item_id = isent.i_item_id
GROUP BY i.i_category
ORDER BY weighted_avg_sentiment DESC
LIMIT 10
