WITH transaction_revenue AS (
    SELECT
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity,
        i.i_price,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
customer_summary AS (
    SELECT
        tr.ws_customer_id,
        SUM(tr.revenue) AS total_revenue,
        SUM(tr.ws_quantity) AS total_quantity,
        COUNT(DISTINCT tr.ws_item_id) AS distinct_items
    FROM transaction_revenue tr
    GROUP BY tr.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cs.total_revenue,
    cs.total_quantity,
    cs.distinct_items,
    RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM customer_summary cs
JOIN customers c
    ON cs.ws_customer_id = c.c_customer_id
ORDER BY revenue_rank
LIMIT 50
