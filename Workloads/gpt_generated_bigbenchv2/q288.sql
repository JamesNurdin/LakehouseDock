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
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) * i.i_price AS total_revenue,
    COALESCE(r.avg_sentiment, NULL) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
ORDER BY total_revenue DESC
LIMIT 100
