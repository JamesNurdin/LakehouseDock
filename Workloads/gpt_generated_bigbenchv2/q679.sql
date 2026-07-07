WITH sales_items AS (
    SELECT ss.ss_store_id,
           i.i_category,
           ss.ss_quantity,
           i.i_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
)
SELECT i_category,
       ss_store_id,
       SUM(ss_quantity) AS total_quantity,
       SUM(i_price * ss_quantity) AS total_revenue
FROM sales_items
GROUP BY i_category, ss_store_id
ORDER BY total_revenue DESC
