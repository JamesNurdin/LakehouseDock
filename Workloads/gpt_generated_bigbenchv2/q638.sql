WITH ws_agg AS (
    SELECT
        ws_customer_id,
        COUNT(DISTINCT ws_item_id) AS distinct_items,
        SUM(ws_quantity) AS total_quantity,
        MIN(ws_ts) AS first_transaction_ts,
        MAX(ws_ts) AS last_transaction_ts
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    ws_agg.distinct_items,
    ws_agg.total_quantity,
    ws_agg.first_transaction_ts,
    ws_agg.last_transaction_ts,
    RANK() OVER (ORDER BY ws_agg.total_quantity DESC) AS quantity_rank
FROM customers AS c
JOIN ws_agg
    ON ws_agg.ws_customer_id = c.c_customer_id
ORDER BY ws_agg.total_quantity DESC
LIMIT 10
