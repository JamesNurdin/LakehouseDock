WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_id
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
       COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0) AS total_quantity_sold,
       r.avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON ss.item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.item_id = i.i_item_id
LEFT JOIN review_agg r ON r.item_id = i.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
