WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
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
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
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
    COALESCE(r_agg.review_count, 0) AS review_count,
    r_agg.avg_rating
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg
    ON ss_agg.i_category_id = ws_agg.i_category_id
    AND ss_agg.i_category_name = ws_agg.i_category_name
LEFT JOIN reviews_agg r_agg
    ON ss_agg.i_category_id = r_agg.i_category_id
    AND ss_agg.i_category_name = r_agg.i_category_name
ORDER BY s.s_store_name, ss_agg.i_category_name
