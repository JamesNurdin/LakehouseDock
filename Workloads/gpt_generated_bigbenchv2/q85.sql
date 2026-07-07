WITH sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_category,
        i.i_price,
        s.s_store_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
)
SELECT
    s_store_name,
    i_category,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_quantity * i_price) AS total_revenue,
    SUM(ss_quantity * i_price) / NULLIF(SUM(ss_quantity), 0) AS avg_unit_price
FROM sales
GROUP BY s_store_name, i_category
ORDER BY total_revenue DESC
LIMIT 10
