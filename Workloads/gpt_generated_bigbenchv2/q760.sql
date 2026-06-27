WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(*) AS store_transactions
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(*) AS web_transactions
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(sa.store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.web_quantity, 0) AS total_web_quantity,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue,
    COALESCE(ra.avg_rating, 0.0) AS average_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    COALESCE(sa.store_transactions, 0) AS store_transactions,
    COALESCE(wa.web_transactions, 0) AS web_transactions
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
WHERE i.i_price > 10
ORDER BY total_revenue DESC
LIMIT 20
