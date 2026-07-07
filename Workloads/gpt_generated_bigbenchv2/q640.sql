WITH sales_by_category AS (
    SELECT
        i.i_category,
        SUM(i.i_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
        AVG(i.i_price) AS avg_item_price
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    WHERE i.i_price > 20
    GROUP BY i.i_category
)
SELECT
    i_category,
    total_sales,
    total_quantity,
    distinct_items_sold,
    avg_item_price
FROM sales_by_category
ORDER BY total_sales DESC
LIMIT 10
