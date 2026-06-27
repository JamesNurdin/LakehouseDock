WITH rating_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),

sales_union AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_quantity AS quantity,
        ss.ss_item_id AS item_id,
        ss.ss_ts AS ts
    FROM store_sales ss
    UNION ALL
    SELECT
        NULL AS store_id,
        ws.ws_quantity AS quantity,
        ws.ws_item_id AS item_id,
        ws.ws_ts AS ts
    FROM web_sales ws
),

sales_by_store_category AS (
    SELECT
        COALESCE(st.s_store_name, 'Online') AS store_name,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        SUM(su.quantity) AS total_quantity,
        SUM(su.quantity * i.i_price) AS total_revenue
    FROM sales_union su
    JOIN items i ON su.item_id = i.i_item_id
    LEFT JOIN stores st ON su.store_id = st.s_store_id
    GROUP BY COALESCE(st.s_store_name, 'Online'), i.i_category_id, i.i_category_name
)
SELECT
    sbc.store_name,
    sbc.category_name,
    sbc.total_quantity,
    sbc.total_revenue,
    rbc.avg_rating
FROM sales_by_store_category sbc
LEFT JOIN rating_by_category rbc
    ON sbc.category_id = rbc.i_category_id
ORDER BY sbc.total_revenue DESC
