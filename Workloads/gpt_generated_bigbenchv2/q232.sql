WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ssa.i_category_id,
    ssa.i_category_name,
    ssa.store_quantity,
    ssa.store_revenue,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    COALESCE(wsa.web_revenue, 0) AS web_revenue,
    ra.avg_rating
FROM store_sales_agg ssa
LEFT JOIN web_sales_agg wsa
    ON ssa.i_category_id = wsa.i_category_id
   AND ssa.i_category_name = wsa.i_category_name
LEFT JOIN rating_agg ra
    ON ssa.i_category_id = ra.i_category_id
   AND ssa.i_category_name = ra.i_category_name
ORDER BY ssa.store_revenue DESC
LIMIT 100
