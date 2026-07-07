WITH sales_per_store AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items,
        AVG(ss.ss_quantity) AS avg_quantity_per_tx
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sp.total_quantity,
    sp.distinct_items,
    sp.avg_quantity_per_tx
FROM sales_per_store sp
JOIN stores s
    ON sp.ss_store_id = s.s_store_id
ORDER BY sp.total_quantity DESC
