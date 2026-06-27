WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS s_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    sa.i_category_name,
    sa.store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    (sa.store_quantity + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    ra.avg_rating,
    ra.review_count
FROM store_sales_agg sa
JOIN stores s ON sa.s_store_id = s.s_store_id
LEFT JOIN web_sales_agg wa ON sa.i_category_id = wa.i_category_id
LEFT JOIN reviews_agg ra ON sa.i_category_id = ra.i_category_id
WHERE ra.avg_rating >= 4
ORDER BY total_quantity DESC
LIMIT 20
