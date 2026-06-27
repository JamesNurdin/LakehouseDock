WITH sales_with_price AS (
    SELECT
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        ss.ss_quantity * i.i_price AS revenue,
        i.i_category_id,
        i.i_category_name,
        i.i_class_id
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    WHERE ss.ss_quantity > 0
)
SELECT
    c.c_customer_id,
    c.c_name,
    swp.i_category_id,
    swp.i_category_name,
    SUM(swp.revenue) AS total_revenue,
    SUM(swp.ss_quantity) AS total_quantity,
    COUNT(DISTINCT swp.ss_item_id) AS distinct_items,
    AVG(swp.i_price) AS avg_price
FROM sales_with_price swp
JOIN customers c
    ON swp.ss_customer_id = c.c_customer_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    swp.i_category_id,
    swp.i_category_name
ORDER BY total_revenue DESC
LIMIT 100
