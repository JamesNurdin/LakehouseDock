WITH customer_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_item_id) AS distinct_items,
        AVG(ws.ws_quantity) AS avg_quantity,
        MAX(CAST(ws.ws_ts AS timestamp)) AS latest_ts
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    ca.c_customer_id,
    ca.c_name,
    ca.total_quantity,
    ca.distinct_items,
    ca.avg_quantity,
    ca.latest_ts,
    ROW_NUMBER() OVER (ORDER BY ca.total_quantity DESC) AS rank_by_quantity
FROM customer_agg ca
ORDER BY rank_by_quantity
LIMIT 10
