WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.item_id
    LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.item_id
),
review_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_item_id = r.i_item_id
ORDER BY s.total_quantity DESC
LIMIT 10
