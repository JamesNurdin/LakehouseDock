WITH sales_detail AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category,
        ss.ss_quantity,
        i.i_price,
        c.c_customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    WHERE i.i_price > 10
)
SELECT
    s_store_name,
    i_category,
    SUM(ss_quantity * i_price) AS total_revenue,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
FROM sales_detail
GROUP BY s_store_name, i_category
ORDER BY total_revenue DESC
LIMIT 20
