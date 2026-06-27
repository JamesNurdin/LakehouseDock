WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
)
SELECT
    s_store_name,
    i_category_name,
    total_quantity,
    total_revenue,
    unique_customers,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_revenue DESC) AS category_revenue_rank
FROM sales_agg
ORDER BY total_revenue DESC
LIMIT 20
