WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_quantity * i_price) AS total_store_revenue,
        COUNT(DISTINCT ss_store_id) AS distinct_store_count
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
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
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_name,
    SUM(COALESCE(sa.total_store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.total_web_quantity, 0)) AS total_web_quantity,
    SUM(COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sa.total_store_revenue, 0)) AS total_store_revenue,
    AVG(COALESCE(ra.avg_rating, 0)) AS avg_rating,
    SUM(COALESCE(sa.distinct_store_count, 0)) AS total_distinct_stores_selling_category,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
GROUP BY i.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
