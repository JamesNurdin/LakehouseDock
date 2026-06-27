WITH store_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity * i.i_price) AS store_spend,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name
),
web_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ws.ws_quantity * i.i_price) AS web_spend,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    COALESCE(s.c_customer_id, w.c_customer_id) AS customer_id,
    COALESCE(s.c_name, w.c_name) AS customer_name,
    COALESCE(s.store_spend, 0) AS total_store_spend,
    COALESCE(s.store_qty, 0) AS total_store_quantity,
    COALESCE(w.web_spend, 0) AS total_web_spend,
    COALESCE(w.web_qty, 0) AS total_web_quantity,
    COALESCE(s.store_spend, 0) + COALESCE(w.web_spend, 0) AS total_spend,
    COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.c_customer_id = w.c_customer_id
ORDER BY total_spend DESC
LIMIT 10
