WITH sales_with_price AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_category_id,
        i.i_category,
        i.i_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    swp.i_category_id,
    swp.i_category,
    SUM(swp.ss_quantity) AS total_quantity,
    SUM(swp.ss_quantity * swp.i_price) AS total_revenue,
    SUM(swp.ss_quantity * swp.i_price) / SUM(swp.ss_quantity) AS avg_price_per_unit
FROM sales_with_price swp
JOIN stores s ON swp.ss_store_id = s.s_store_id
GROUP BY s.s_store_id, s.s_store_name, swp.i_category_id, swp.i_category
ORDER BY total_revenue DESC
LIMIT 10
