WITH store_agg AS (
    SELECT
        ss_customer_id,
        SUM(ss_quantity) AS store_qty_total,
        COUNT(DISTINCT ss_item_id) AS store_distinct_items,
        MIN(ss_ts) AS store_first_ts
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        SUM(ws_quantity) AS web_qty_total,
        COUNT(DISTINCT ws_item_id) AS web_distinct_items,
        MIN(ws_ts) AS web_first_ts
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(s.store_qty_total, 0) AS total_store_qty,
    COALESCE(w.web_qty_total, 0) AS total_web_qty,
    COALESCE(s.store_distinct_items, 0) AS store_distinct_items,
    COALESCE(w.web_distinct_items, 0) AS web_distinct_items,
    CASE
        WHEN COALESCE(s.store_qty_total, 0) + COALESCE(w.web_qty_total, 0) > 0
        THEN COALESCE(s.store_qty_total, 0) * 1.0 / (COALESCE(s.store_qty_total, 0) + COALESCE(w.web_qty_total, 0))
        ELSE NULL
    END AS store_qty_ratio,
    LEAST(
        COALESCE(s.store_first_ts, '9999-12-31'),
        COALESCE(w.web_first_ts, '9999-12-31')
    ) AS first_transaction_ts
FROM customers c
LEFT JOIN store_agg s
    ON s.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg w
    ON w.ws_customer_id = c.c_customer_id
ORDER BY total_store_qty DESC, total_web_qty DESC
LIMIT 100
