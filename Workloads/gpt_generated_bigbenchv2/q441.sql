WITH store_category_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS category_revenue,
        SUM(ss.ss_quantity) AS category_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
store_total_sales AS (
    SELECT
        ss_store_id,
        SUM(category_revenue) AS total_revenue,
        SUM(category_quantity) AS total_quantity
    FROM store_category_sales
    GROUP BY ss_store_id
)
SELECT
    scs.s_store_name,
    scs.i_category_name,
    scs.category_quantity,
    scs.category_revenue,
    st.total_quantity,
    st.total_revenue,
    (scs.category_revenue / st.total_revenue) * 100.0 AS revenue_share_pct,
    (scs.category_quantity / st.total_quantity) * 100.0 AS quantity_share_pct
FROM store_category_sales scs
JOIN store_total_sales st
    ON scs.ss_store_id = st.ss_store_id
ORDER BY scs.s_store_name, scs.category_revenue DESC
