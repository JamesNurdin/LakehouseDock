WITH
    store_agg AS (
        SELECT
            c.c_customer_id,
            c.c_name,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_transaction_id) AS store_transactions
        FROM customers c
        JOIN store_sales ss ON ss.ss_customer_id = c.c_customer_id
        GROUP BY c.c_customer_id, c.c_name
    ),
    web_agg AS (
        SELECT
            c.c_customer_id,
            c.c_name,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_transaction_id) AS web_transactions
        FROM customers c
        JOIN web_sales ws ON ws.ws_customer_id = c.c_customer_id
        GROUP BY c.c_customer_id, c.c_name
    ),
    combined AS (
        SELECT
            COALESCE(s.c_customer_id, w.c_customer_id) AS customer_id,
            COALESCE(s.c_name, w.c_name)           AS customer_name,
            COALESCE(s.store_quantity, 0)          AS store_quantity,
            COALESCE(w.web_quantity, 0)            AS web_quantity,
            COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
            COALESCE(s.store_transactions, 0)      AS store_transactions,
            COALESCE(w.web_transactions, 0)        AS web_transactions
        FROM store_agg s
        FULL OUTER JOIN web_agg w ON w.c_customer_id = s.c_customer_id
    )
SELECT
    customer_id,
    customer_name,
    store_quantity,
    web_quantity,
    total_quantity,
    store_transactions,
    web_transactions,
    CASE WHEN total_quantity = 0 THEN 0
         ELSE CAST(store_quantity AS double) / total_quantity
    END AS store_share,
    rank() OVER (ORDER BY total_quantity DESC) AS total_quantity_rank
FROM combined
ORDER BY store_share DESC, total_quantity DESC
LIMIT 100
