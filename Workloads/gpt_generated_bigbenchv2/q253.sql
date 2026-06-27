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
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(*) AS category_review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_name,
    ss_agg.i_category_name,
    ss_agg.total_store_quantity,
    ss_agg.total_store_revenue,
    COALESCE(ws_agg.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ws_agg.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(cr.avg_category_rating, 0) AS avg_category_rating,
    COALESCE(cr.category_review_count, 0) AS category_review_count
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg
    ON ss_agg.i_category_id = ws_agg.i_category_id
LEFT JOIN category_ratings cr
    ON ss_agg.i_category_id = cr.i_category_id
ORDER BY (ss_agg.total_store_revenue + COALESCE(ws_agg.total_web_revenue, 0)) DESC
LIMIT 10
