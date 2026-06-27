WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.i_category_id,
    sa.i_category_name,
    sa.total_quantity AS store_quantity,
    sa.total_revenue AS store_revenue,
    wa.total_quantity AS web_quantity,
    wa.total_revenue AS web_revenue,
    CASE 
        WHEN (sa.total_quantity + wa.total_quantity) = 0 THEN 0
        ELSE 100.0 * wa.total_quantity / (sa.total_quantity + wa.total_quantity)
    END AS web_quantity_pct,
    CASE 
        WHEN (sa.total_revenue + wa.total_revenue) = 0 THEN 0
        ELSE 100.0 * wa.total_revenue / (sa.total_revenue + wa.total_revenue)
    END AS web_revenue_pct
FROM store_agg sa
LEFT JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
    AND sa.i_category_name = wa.i_category_name
ORDER BY sa.s_store_name, sa.i_category_name
