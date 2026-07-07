WITH revenue_by_customer AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        i.i_category
),
ranked AS (
    SELECT
        r.c_customer_id,
        r.c_name,
        r.i_category,
        r.total_quantity,
        r.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY r.i_category ORDER BY r.total_revenue DESC) AS rank_in_category
    FROM revenue_by_customer r
)
SELECT
    c_customer_id,
    c_name,
    i_category,
    total_quantity,
    total_revenue,
    rank_in_category
FROM ranked
WHERE rank_in_category <= 5
ORDER BY i_category, rank_in_category
