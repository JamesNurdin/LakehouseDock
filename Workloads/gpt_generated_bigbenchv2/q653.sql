WITH store_agg AS (
    SELECT
        ss_customer_id,
        COUNT(*) AS store_txn_count,
        SUM(ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss_item_id) AS distinct_store_items,
        MAX(ss_ts) AS max_store_ts
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        COUNT(*) AS web_txn_count,
        SUM(ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws_item_id) AS distinct_web_items,
        MAX(ws_ts) AS max_web_ts
    FROM web_sales
    GROUP BY ws_customer_id
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        COALESCE(s.store_txn_count, 0) AS store_txn_count,
        COALESCE(w.web_txn_count, 0) AS web_txn_count,
        COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
        COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
        COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
        COALESCE(s.distinct_store_items, 0) AS distinct_store_items,
        COALESCE(w.distinct_web_items, 0) AS distinct_web_items,
        GREATEST(COALESCE(s.max_store_ts, ''), COALESCE(w.max_web_ts, '')) AS most_recent_ts
    FROM customers c
    LEFT JOIN store_agg s
        ON s.ss_customer_id = c.c_customer_id
    LEFT JOIN web_agg w
        ON w.ws_customer_id = c.c_customer_id
)
SELECT
    c_customer_id,
    c_name,
    store_txn_count,
    web_txn_count,
    total_store_quantity,
    total_web_quantity,
    total_quantity,
    distinct_store_items,
    distinct_web_items,
    most_recent_ts,
    ROW_NUMBER() OVER (ORDER BY total_quantity DESC) AS rank
FROM customer_sales
ORDER BY rank
LIMIT 10
