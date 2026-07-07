WITH store_agg AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_store_items
    FROM store_sales ss
    GROUP BY ss.ss_customer_id
),
web_agg AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_item_id) AS distinct_web_items
    FROM web_sales ws
    GROUP BY ws.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
    COALESCE(s.distinct_store_items, 0) AS distinct_store_items,
    COALESCE(w.distinct_web_items, 0) AS distinct_web_items,
    COALESCE(s.distinct_store_items, 0) + COALESCE(w.distinct_web_items, 0) AS distinct_total_items
FROM customers c
LEFT JOIN store_agg s
    ON s.customer_id = c.c_customer_id
LEFT JOIN web_agg w
    ON w.customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 10
