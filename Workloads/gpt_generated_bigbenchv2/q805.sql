WITH store_agg AS (
    SELECT
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_spent
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_customer_id
),
web_agg AS (
    SELECT
        ws.ws_customer_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_spent
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sa.store_qty, 0) AS store_quantity,
    COALESCE(sa.store_spent, 0.0) AS store_spent,
    COALESCE(wa.web_qty, 0) AS web_quantity,
    COALESCE(wa.web_spent, 0.0) AS web_spent,
    COALESCE(sa.store_spent, 0.0) + COALESCE(wa.web_spent, 0.0) AS total_spent,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sa.store_spent, 0.0) + COALESCE(wa.web_spent, 0.0) DESC) AS spend_rank
FROM customers c
LEFT JOIN store_agg sa ON c.c_customer_id = sa.ss_customer_id
LEFT JOIN web_agg wa ON c.c_customer_id = wa.ws_customer_id
ORDER BY total_spent DESC
LIMIT 10
