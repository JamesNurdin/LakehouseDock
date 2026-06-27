WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
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
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count,
    CASE
        WHEN SUM(COALESCE(ra.review_count, 0)) > 0 THEN
            SUM(COALESCE(ra.avg_rating * ra.review_count, 0)) / SUM(COALESCE(ra.review_count, 0))
        ELSE NULL
    END AS avg_rating
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
