WITH item_sales AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_item_id
)
SELECT
    i.i_category,
    SUM(isales.total_quantity) AS category_quantity,
    SUM(isales.total_revenue) AS category_revenue,
    AVG(i.i_price) AS avg_item_price,
    COUNT(DISTINCT i.i_item_id) AS distinct_items
FROM item_sales isales
JOIN items i
    ON isales.ss_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY category_revenue DESC
LIMIT 10
