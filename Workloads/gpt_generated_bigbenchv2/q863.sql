WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity_sold
    FROM items i
    LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
    LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
),
review_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.i_category,
    s.i_name,
    s.total_quantity_sold,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
JOIN review_agg r ON r.i_item_id = s.i_item_id
ORDER BY s.total_quantity_sold DESC
LIMIT 10
