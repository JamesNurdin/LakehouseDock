WITH store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS category_revenue,
        SUM(ss.ss_quantity) AS category_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
ranked AS (
    SELECT
        scs.s_store_name,
        scs.i_category_name,
        scs.category_revenue,
        scs.category_quantity,
        scs.distinct_customers,
        RANK() OVER (PARTITION BY scs.s_store_name ORDER BY scs.category_revenue DESC) AS revenue_rank
    FROM store_category_sales scs
)
SELECT
    r.s_store_name,
    r.i_category_name,
    r.category_revenue,
    r.category_quantity,
    r.distinct_customers,
    r.revenue_rank
FROM ranked r
WHERE r.revenue_rank <= 3
ORDER BY r.s_store_name, r.revenue_rank
