WITH store_metrics AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name, s.s_store_id, s.s_store_name
),
web_metrics AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_metrics AS (
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
    sm.i_category_id,
    sm.i_category_name,
    sm.s_store_id,
    sm.s_store_name,
    sm.store_qty,
    sm.store_revenue,
    wm.web_qty,
    wm.web_revenue,
    rm.review_count,
    rm.avg_rating
FROM store_metrics sm
LEFT JOIN web_metrics wm
    ON sm.i_category_id = wm.i_category_id
LEFT JOIN review_metrics rm
    ON sm.i_category_id = rm.i_category_id
ORDER BY sm.i_category_name, sm.s_store_name
