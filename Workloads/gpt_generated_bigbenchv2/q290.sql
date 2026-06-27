WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        'Store' AS channel,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(COALESCE(ir.avg_rating, 0) * ss.ss_quantity) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        NULL AS store_id,
        'Web' AS channel,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        SUM(COALESCE(ir.avg_rating, 0) * ws.ws_quantity) / NULLIF(SUM(ws.ws_quantity), 0) AS weighted_avg_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
combined_sales AS (
    SELECT
        store_id,
        channel,
        category_id,
        category_name,
        total_quantity,
        total_revenue,
        weighted_avg_rating
    FROM store_sales_agg
    UNION ALL
    SELECT
        store_id,
        channel,
        category_id,
        category_name,
        total_quantity,
        total_revenue,
        weighted_avg_rating
    FROM web_sales_agg
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    cs.channel,
    cs.category_name,
    cs.total_quantity,
    cs.total_revenue,
    cs.weighted_avg_rating
FROM combined_sales cs
LEFT JOIN stores s ON cs.store_id = s.s_store_id
ORDER BY cs.total_quantity DESC
LIMIT 20
