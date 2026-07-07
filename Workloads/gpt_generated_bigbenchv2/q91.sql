WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        SUM(pr_sentiment) AS total_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COALESCE(SUM(sa.total_store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wa.total_web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(ra.review_count), 0) AS total_review_count,
    CASE WHEN SUM(ra.review_count) > 0 THEN SUM(ra.total_sentiment) / SUM(ra.review_count) END AS avg_sentiment_per_category,
    AVG(i.i_price) AS avg_item_price
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_store_quantity DESC
