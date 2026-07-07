WITH review_agg AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.web_quantity, 0)) AS total_web_quantity,
    AVG(r.avg_sentiment) AS avg_review_sentiment,
    SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
