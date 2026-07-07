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
product_reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_id,
       i.i_category,
       COALESCE(pr.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(pr.review_count, 0) AS review_count,
       COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(ws.total_web_quantity, 0) AS total_web_quantity
FROM items i
LEFT JOIN product_reviews_agg pr ON pr.pr_item_id = i.i_item_id
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
ORDER BY i.i_category_id, i.i_item_id
