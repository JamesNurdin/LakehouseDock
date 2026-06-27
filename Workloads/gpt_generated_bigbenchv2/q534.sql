WITH store_category_revenue AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(i.i_price - i.i_comp_price) AS avg_price_diff,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
)
SELECT
    scr.s_store_name,
    scr.i_category_name,
    scr.total_revenue,
    scr.total_quantity,
    scr.avg_price_diff,
    scr.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY scr.s_store_name ORDER BY scr.total_revenue DESC) AS category_rank
FROM store_category_revenue scr
ORDER BY scr.s_store_name, category_rank
