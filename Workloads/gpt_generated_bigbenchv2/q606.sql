WITH category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        AVG(i.i_price - i.i_comp_price) AS avg_price_diff
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    WHERE ws.ws_quantity > 0
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cs.avg_price_diff,
    RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank,
    SUM(cs.total_revenue) OVER (
        ORDER BY cs.total_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM category_sales cs
ORDER BY cs.total_revenue DESC
