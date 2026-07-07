WITH sales_items AS (
    SELECT
        ss.ss_store_id,
        ss.ss_quantity,
        ss.ss_item_id,
        i.i_category,
        i.i_class_id,
        i.i_price
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    WHERE i.i_category IS NOT NULL
)
SELECT
    si.i_category,
    si.i_class_id,
    SUM(si.ss_quantity) AS total_quantity,
    SUM(si.i_price * si.ss_quantity) AS total_revenue,
    AVG(si.i_price) AS avg_price
FROM sales_items si
GROUP BY si.i_category, si.i_class_id
ORDER BY total_revenue DESC
LIMIT 10
