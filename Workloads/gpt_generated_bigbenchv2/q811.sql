WITH sales_revenue AS (
    SELECT
        ss.ss_store_id AS s_store_id,
        s.s_store_name,
        ss.ss_quantity,
        i.i_price,
        i.i_category_id,
        i.i_category_name,
        (ss.ss_quantity * i.i_price) AS revenue,
        ss.ss_customer_id
    FROM store_sales ss
    JOIN stores s   ON ss.ss_store_id = s.s_store_id
    JOIN items i    ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
store_category_agg AS (
    SELECT
        sr.s_store_id,
        sr.s_store_name,
        sr.i_category_id,
        sr.i_category_name,
        SUM(sr.revenue)                     AS category_revenue,
        SUM(sr.ss_quantity)                 AS category_quantity,
        COUNT(DISTINCT sr.ss_customer_id)   AS category_distinct_customers
    FROM sales_revenue sr
    GROUP BY
        sr.s_store_id,
        sr.s_store_name,
        sr.i_category_id,
        sr.i_category_name
),
store_total AS (
    SELECT
        sca.s_store_id,
        SUM(sca.category_revenue) AS store_total_revenue
    FROM store_category_agg sca
    GROUP BY sca.s_store_id
)
SELECT
    sca.s_store_id,
    sca.s_store_name,
    sca.i_category_id,
    sca.i_category_name,
    sca.category_revenue,
    sca.category_quantity,
    sca.category_distinct_customers,
    (sca.category_revenue / NULLIF(st.store_total_revenue, 0)) * 100 AS revenue_pct_of_store,
    RANK() OVER (PARTITION BY sca.s_store_id ORDER BY sca.category_revenue DESC) AS category_revenue_rank
FROM store_category_agg sca
JOIN store_total st ON sca.s_store_id = st.s_store_id
ORDER BY sca.s_store_id, category_revenue_rank
