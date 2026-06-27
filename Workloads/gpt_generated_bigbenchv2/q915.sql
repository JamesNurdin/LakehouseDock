WITH category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        COUNT(DISTINCT ws.ws_item_id) AS distinct_items_sold,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        AVG(i.i_price) AS avg_item_price,
        AVG(i.i_comp_price) AS avg_comp_price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.distinct_items_sold,
    cs.total_quantity,
    cs.total_revenue,
    cs.avg_item_price,
    cs.avg_comp_price,
    cs.avg_item_price - cs.avg_comp_price AS avg_price_diff,
    RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM category_sales cs
ORDER BY revenue_rank
LIMIT 10
