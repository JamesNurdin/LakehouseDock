WITH sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
total_sales AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.total_quantity, 0) + COALESCE(w.total_quantity, 0) AS total_quantity
    FROM sales_agg s
    FULL OUTER JOIN web_agg w ON s.item_id = w.item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       ts.total_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM total_sales ts
JOIN items i ON i.i_item_id = ts.item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
ORDER BY ts.total_quantity DESC
LIMIT 10
