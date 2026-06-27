WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    ssagg.i_category_name,
    ssagg.store_quantity,
    ssagg.store_revenue,
    COALESCE(wsagg.web_quantity, 0) AS web_quantity,
    COALESCE(wsagg.web_revenue, 0) AS web_revenue,
    COALESCE(ragg.review_count, 0) AS review_count,
    ragg.avg_rating
FROM store_sales_agg ssagg
JOIN stores s
    ON ssagg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wsagg
    ON ssagg.i_category_id = wsagg.i_category_id
LEFT JOIN reviews_agg ragg
    ON ssagg.i_category_id = ragg.i_category_id
ORDER BY s.s_store_name, ssagg.store_revenue DESC
