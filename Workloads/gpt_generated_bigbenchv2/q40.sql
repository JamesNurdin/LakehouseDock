WITH item_sales AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_item_sales AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_total_sales AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM item_sales s
    FULL OUTER JOIN web_item_sales w ON s.item_id = w.item_id
),
item_sentiment AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       SUM(ts.total_quantity) AS total_quantity_sold,
       AVG(isent.avg_sentiment) AS avg_item_sentiment,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM item_total_sales ts
JOIN items i ON ts.item_id = i.i_item_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
