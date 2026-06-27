WITH store_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
online_customers AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(DISTINCT ws.ws_customer_id) AS online_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sm.s_store_id,
    sm.s_store_name,
    sm.i_category_id,
    sm.i_category_name,
    sm.total_quantity,
    sm.total_revenue,
    cr.avg_rating,
    cr.review_count,
    oc.online_customer_count
FROM store_metrics sm
LEFT JOIN category_ratings cr
    ON sm.i_category_id = cr.i_category_id
    AND sm.i_category_name = cr.i_category_name
LEFT JOIN online_customers oc
    ON sm.i_category_id = oc.i_category_id
    AND sm.i_category_name = oc.i_category_name
ORDER BY sm.total_revenue DESC
LIMIT 100
