WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ssagg.i_category_id,
    ssagg.i_category_name,
    ssagg.store_quantity,
    ssagg.store_revenue,
    ssagg.store_customers,
    COALESCE(wsagg.web_quantity, 0) AS web_quantity,
    COALESCE(wsagg.web_revenue, 0) AS web_revenue,
    COALESCE(wsagg.web_customers, 0) AS web_customers,
    COALESCE(review_agg.avg_rating, 0) AS avg_rating,
    COALESCE(review_agg.review_count, 0) AS total_reviews
FROM store_sales_agg ssagg
JOIN stores s ON ssagg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wsagg ON ssagg.i_category_id = wsagg.i_category_id
LEFT JOIN review_agg ON ssagg.i_category_id = review_agg.i_category_id
ORDER BY ssagg.store_revenue DESC
