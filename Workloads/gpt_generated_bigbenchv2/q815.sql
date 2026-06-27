WITH sales_joined AS (
    SELECT
        ws.ws_quantity,
        CAST(ws.ws_ts AS timestamp) AS ws_timestamp,
        c.c_customer_id,
        c.c_name,
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        (ws.ws_quantity * i.i_price) AS revenue
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    WHERE ws.ws_quantity > 0
      AND i.i_price > 0
      AND CAST(ws.ws_ts AS timestamp) >= TIMESTAMP '2022-01-01'
),
aggregated_sales AS (
    SELECT
        c_customer_id,
        c_name,
        i_category_id,
        i_category_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        AVG(i_price) AS avg_item_price,
        COUNT(DISTINCT i_item_id) AS distinct_items
    FROM sales_joined
    GROUP BY
        c_customer_id,
        c_name,
        i_category_id,
        i_category_name
)
SELECT
    c_customer_id,
    c_name,
    i_category_id,
    i_category_name,
    total_quantity,
    total_revenue,
    avg_item_price,
    distinct_items,
    RANK() OVER (PARTITION BY c_customer_id ORDER BY total_revenue DESC) AS category_revenue_rank
FROM aggregated_sales
ORDER BY total_revenue DESC
LIMIT 100
