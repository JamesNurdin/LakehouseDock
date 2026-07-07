WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
total_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           i.i_price,
           COALESCE(ss.store_quantity, 0) AS store_quantity,
           COALESCE(ws.web_quantity, 0) AS web_quantity,
           COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
    LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT t.i_item_id,
       t.i_name,
       t.i_category,
       t.i_price,
       t.total_quantity,
       r.review_count,
       r.avg_sentiment
FROM total_sales t
LEFT JOIN reviews_agg r ON t.i_item_id = r.pr_item_id
ORDER BY t.total_quantity DESC
LIMIT 10
