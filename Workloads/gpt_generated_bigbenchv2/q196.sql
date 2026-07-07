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
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(ss.total_store_quantity, 0)) AS total_store_quantity,
       SUM(COALESCE(ws.total_web_quantity, 0)) AS total_web_quantity,
       SUM(COALESCE(r.review_count, 0)) AS review_count,
       AVG(r.avg_sentiment) AS avg_sentiment
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY (total_store_quantity + total_web_quantity) DESC
LIMIT 10
