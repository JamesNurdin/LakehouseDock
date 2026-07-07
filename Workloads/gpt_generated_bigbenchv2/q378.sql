WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
sales_per_item AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
    LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sales_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(total_quantity) AS total_quantity
    FROM sales_per_item
    GROUP BY i_category_id, i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 10
