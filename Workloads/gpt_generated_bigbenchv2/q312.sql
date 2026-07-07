WITH sales_with_price AS (
    SELECT
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        i.i_category
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
)
SELECT
    i_category,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_quantity * i_price) AS total_revenue
FROM sales_with_price
GROUP BY i_category
ORDER BY total_revenue DESC
LIMIT 10
