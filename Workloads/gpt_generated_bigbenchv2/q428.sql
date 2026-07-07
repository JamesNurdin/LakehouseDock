WITH store_agg AS (
    SELECT ss_customer_id AS c_customer_id,
           COUNT(*) AS store_txn_cnt,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT ws_customer_id AS c_customer_id,
           COUNT(*) AS web_txn_cnt,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       COALESCE(s.store_txn_cnt, 0) AS store_txn_cnt,
       COALESCE(s.store_qty, 0) AS store_qty,
       COALESCE(w.web_txn_cnt, 0) AS web_txn_cnt,
       COALESCE(w.web_qty, 0) AS web_qty,
       (COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) AS total_qty
FROM customers c
LEFT JOIN store_agg s
    ON s.c_customer_id = c.c_customer_id
LEFT JOIN web_agg w
    ON w.c_customer_id = c.c_customer_id
ORDER BY total_qty DESC
