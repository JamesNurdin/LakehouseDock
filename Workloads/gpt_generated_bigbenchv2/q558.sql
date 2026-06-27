WITH store_agg AS (
    SELECT
        ss_customer_id AS customer_id,
        COUNT(ss_transaction_id) AS store_txn_cnt,
        SUM(ss_quantity) AS store_qty,
        COUNT(DISTINCT ss_store_id) AS distinct_store_cnt
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id AS customer_id,
        COUNT(ws_transaction_id) AS web_txn_cnt,
        SUM(ws_quantity) AS web_qty,
        COUNT(DISTINCT ws_item_id) AS distinct_web_item_cnt
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(s.store_txn_cnt, 0) AS store_txn_cnt,
    COALESCE(s.store_qty, 0) AS store_qty,
    COALESCE(w.web_txn_cnt, 0) AS web_txn_cnt,
    COALESCE(w.web_qty, 0) AS web_qty,
    COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
    ROW_NUMBER() OVER (
        ORDER BY COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) DESC
    ) AS rank_by_quantity
FROM customers AS c
LEFT JOIN store_agg AS s
    ON s.customer_id = c.c_customer_id
LEFT JOIN web_agg AS w
    ON w.customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 20
