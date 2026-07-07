WITH sales_by_item AS (
    SELECT
        i.i_category_id,
        i.i_category,
        i.i_item_id,
        i.i_name,
        i.i_price,
        ws.ws_quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    INNER JOIN items i
        ON ws.ws_item_id = i.i_item_id
    WHERE i.i_price > 0
)
SELECT
    s.i_category_id,
    s.i_category,
    COUNT(DISTINCT s.i_item_id) AS distinct_items_sold,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.revenue) AS total_revenue,
    AVG(s.i_price) AS avg_item_price
FROM sales_by_item s
GROUP BY s.i_category_id, s.i_category
ORDER BY total_revenue DESC
LIMIT 10
