WITH sales AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
sales_combined AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_qty, 0) AS store_qty,
           COALESCE(w.web_qty, 0) AS web_qty,
           COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty
    FROM sales s
    FULL OUTER JOIN web w ON s.item_id = w.item_id
),
reviews AS (
    SELECT pr_item_id AS item_id,
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       sc.total_qty,
       sc.store_qty,
       sc.web_qty,
       r.review_count,
       r.avg_sentiment
FROM sales_combined sc
JOIN items i ON sc.item_id = i.i_item_id
LEFT JOIN reviews r ON i.i_item_id = r.item_id
ORDER BY sc.total_qty DESC
LIMIT 10
