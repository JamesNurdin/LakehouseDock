WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_reviews AS (
    SELECT
        i.i_category_id,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS category_review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    s.s_store_name,
    ssagg.i_category_name,
    ssagg.total_store_quantity,
    ssagg.total_store_revenue,
    COALESCE(wsagg.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wsagg.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(cr.avg_category_rating, 0) AS avg_category_rating,
    COALESCE(cr.category_review_count, 0) AS category_review_count
FROM store_sales_agg ssagg
JOIN stores s ON ssagg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wsagg ON ssagg.i_category_id = wsagg.i_category_id
LEFT JOIN category_reviews cr ON ssagg.i_category_id = cr.i_category_id
ORDER BY ssagg.total_store_revenue DESC
LIMIT 50
