WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss_store_id) AS store_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_count, 0) AS number_of_stores_selling,
    ra.avg_rating AS average_rating,
    COALESCE(ra.review_count, 0) AS number_of_reviews,
    (COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) * i.i_price AS total_revenue
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
WHERE COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) > 0
ORDER BY total_quantity DESC
LIMIT 10
