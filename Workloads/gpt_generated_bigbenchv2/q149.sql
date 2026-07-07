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
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COUNT(DISTINCT i.i_item_id) AS distinct_item_count,
    COALESCE(SUM(ss.store_qty), 0) AS total_store_quantity,
    COALESCE(SUM(ws.web_qty), 0) AS total_web_quantity,
    COALESCE(SUM(ss.store_qty), 0) + COALESCE(SUM(ws.web_qty), 0) AS total_quantity,
    ROUND(AVG(r.avg_sentiment), 2) AS avg_review_sentiment,
    ROUND(AVG(i.i_price), 2) AS avg_item_price
FROM items i
LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.i_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity DESC
