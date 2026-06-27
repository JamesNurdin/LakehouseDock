WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ss.ss_quantity * i.i_price) AS total_store_rev
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_qty,
        SUM(ws.ws_quantity * i.i_price) AS total_web_rev
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ss_agg.i_category_id,
    ss_agg.i_category_name,
    ss_agg.total_store_qty,
    ss_agg.total_store_rev,
    COALESCE(ws_agg.total_web_qty, 0) AS total_web_qty,
    COALESCE(ws_agg.total_web_rev, 0) AS total_web_rev,
    COALESCE(rv_agg.avg_rating, 0) AS avg_rating
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg
    ON ss_agg.i_category_id = ws_agg.i_category_id
    AND ss_agg.i_category_name = ws_agg.i_category_name
LEFT JOIN review_agg rv_agg
    ON ss_agg.i_category_id = rv_agg.i_category_id
    AND ss_agg.i_category_name = rv_agg.i_category_name
ORDER BY s.s_store_name, ss_agg.i_category_name
