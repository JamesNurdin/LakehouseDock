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
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category,
    i.i_name,
    COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
    ra.avg_sentiment,
    ra.review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg ra ON ra.pr_item_id = i.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY total_store_quantity DESC
LIMIT 100
