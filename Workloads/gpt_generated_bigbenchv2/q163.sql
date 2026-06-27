WITH sales_details AS (
    SELECT
        ss.ss_transaction_id,
        ss.ss_customer_id,
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        ss.ss_ts,
        c.c_name AS c_name,
        i.i_name AS i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_class_id,
        s.s_store_name AS s_store_name
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
)
SELECT
    s_store_name,
    i_category_name,
    SUM(ss_quantity * i_price) AS total_revenue,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss_customer_id) AS distinct_customers,
    AVG(i_price) AS avg_item_price
FROM sales_details
GROUP BY s_store_name, i_category_name
ORDER BY total_revenue DESC
LIMIT 20
