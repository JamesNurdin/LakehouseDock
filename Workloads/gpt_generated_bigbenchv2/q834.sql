WITH store_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_qty,
        COUNT(DISTINCT ss_customer_id) AS store_customer_cnt
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_qty,
        COUNT(DISTINCT ws_customer_id) AS web_customer_cnt
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) AS total_quantity_sold,
    SUM((COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) * i.i_price) AS total_revenue,
    SUM(COALESCE(ra.avg_rating * ra.review_cnt, 0)) / NULLIF(SUM(COALESCE(ra.review_cnt, 0)), 0) AS avg_item_rating,
    SUM(COALESCE(ra.review_cnt, 0)) AS total_reviews,
    SUM(COALESCE(sa.store_customer_cnt, 0) + COALESCE(wa.web_customer_cnt, 0)) AS total_customer_counts
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
