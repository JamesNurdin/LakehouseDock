WITH sales_by_customer_category AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity * i.i_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT i.i_item_id) AS distinct_items
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category
)
SELECT
    c_customer_id,
    c_name,
    i_category_id,
    i_category,
    total_sales,
    total_quantity,
    distinct_items,
    total_sales / total_quantity AS avg_price_per_unit
FROM sales_by_customer_category
ORDER BY total_sales DESC
LIMIT 100
