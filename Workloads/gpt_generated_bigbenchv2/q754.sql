WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_agg s
    FULL OUTER JOIN web_agg w ON s.item_id = w.item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_category_id,
       i.i_price,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
ORDER BY s.total_quantity DESC
LIMIT 10
