WITH store_sales_by_customer AS (
    SELECT
        ss_customer_id,
        COUNT(ss_transaction_id) AS store_transaction_count,
        SUM(ss_quantity) AS store_total_quantity,
        MAX(ss_ts) AS store_last_ts
    FROM store_sales
    GROUP BY ss_customer_id
),
web_sales_by_customer AS (
    SELECT
        ws_customer_id,
        COUNT(ws_transaction_id) AS web_transaction_count,
        SUM(ws_quantity) AS web_total_quantity,
        MAX(ws_ts) AS web_last_ts
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(s.store_transaction_count, 0) AS store_transaction_count,
    COALESCE(s.store_total_quantity, 0) AS store_total_quantity,
    COALESCE(w.web_transaction_count, 0) AS web_transaction_count,
    COALESCE(w.web_total_quantity, 0) AS web_total_quantity,
    CASE
        WHEN COALESCE(w.web_total_quantity, 0) = 0 THEN NULL
        ELSE CAST(COALESCE(s.store_total_quantity, 0) AS double) / COALESCE(w.web_total_quantity, 0)
    END AS store_to_web_quantity_ratio,
    GREATEST(
        COALESCE(s.store_last_ts, ''),
        COALESCE(w.web_last_ts, '')
    ) AS most_recent_ts
FROM customers c
LEFT JOIN store_sales_by_customer s
    ON s.ss_customer_id = c.c_customer_id
LEFT JOIN web_sales_by_customer w
    ON w.ws_customer_id = c.c_customer_id
WHERE COALESCE(s.store_total_quantity, 0) + COALESCE(w.web_total_quantity, 0) > 0
ORDER BY store_to_web_quantity_ratio DESC NULLS LAST
LIMIT 100
