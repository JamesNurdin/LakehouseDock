WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id, ss.ss_store_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(ssa.total_store_quantity, 0) AS store_quantity,
    COALESCE(wsa.total_web_quantity, 0) AS web_quantity,
    COALESCE(ssa.total_store_revenue, 0) AS store_revenue,
    COALESCE(wsa.total_web_revenue, 0) AS web_revenue,
    COALESCE(ra.review_count, 0) AS review_count,
    ra.avg_rating
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
LEFT JOIN stores s ON ssa.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg ra ON ra.pr_item_id = i.i_item_id
WHERE i.i_price > 10
ORDER BY s.s_store_name, i.i_category_name, i.i_name
