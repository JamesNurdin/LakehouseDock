WITH sales_enriched AS (
    SELECT
        ss.ss_quantity,
        ss.ss_customer_id,
        ss.ss_store_id,
        ss.ss_item_id,
        c.c_name,
        s.s_store_name,
        i.i_category,
        i.i_price,
        (ss.ss_quantity * i.i_price) AS line_total
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
)
SELECT
    s_store_name,
    i_category,
    SUM(line_total) AS total_sales_amount,
    SUM(ss_quantity) AS total_units_sold,
    COUNT(DISTINCT ss_customer_id) AS distinct_customers
FROM sales_enriched
GROUP BY s_store_name, i_category
ORDER BY total_sales_amount DESC
LIMIT 10
