WITH store_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(sa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.web_quantity, 0)) AS total_web_quantity,
    AVG(i.i_price) AS avg_item_price,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_store_quantity + total_web_quantity DESC
LIMIT 10
