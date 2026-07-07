WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(ss_agg.total_store_quantity, 0) + COALESCE(ws_agg.total_web_quantity, 0) AS total_quantity_sold,
       COALESCE(ss_agg.total_store_quantity, 0) AS store_quantity,
       COALESCE(ws_agg.total_web_quantity, 0) AS web_quantity,
       r_agg.avg_sentiment,
       COALESCE(r_agg.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss_agg ON ss_agg.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws_agg ON ws_agg.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r_agg ON r_agg.pr_item_id = i.i_item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
