WITH store_agg AS (
    SELECT
        ss_customer_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_transaction_id) AS store_transactions
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_transaction_id) AS web_transactions
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    CASE
        WHEN (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) = 0 THEN 0
        ELSE COALESCE(sa.store_quantity, 0) * 1.0 / (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0))
    END AS store_share
FROM customers c
LEFT JOIN store_agg sa ON sa.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg wa ON wa.ws_customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 100
