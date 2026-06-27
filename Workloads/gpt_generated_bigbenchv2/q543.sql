WITH store_cust_store_agg AS (
    SELECT
        ss_customer_id,
        ss_store_id,
        SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_customer_id, ss_store_id
),
web_cust_agg AS (
    SELECT
        ws_customer_id,
        SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_customer_id
),
cust_store_rank AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ss.ss_store_id,
        ss.store_qty,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.store_qty DESC) AS rn
    FROM customers c
    JOIN store_cust_store_agg ss
        ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
),
best_store_per_cust AS (
    SELECT
        c_customer_id,
        c_name,
        ss_store_id,
        store_qty
    FROM cust_store_rank
    WHERE rn = 1
),
total_per_cust AS (
    SELECT
        c.c_customer_id,
        COALESCE(st.store_qty, 0) + COALESCE(wb.web_qty, 0) AS total_qty
    FROM customers c
    LEFT JOIN (
        SELECT ss_customer_id, SUM(ss_quantity) AS store_qty
        FROM store_sales
        GROUP BY ss_customer_id
    ) st ON st.ss_customer_id = c.c_customer_id
    LEFT JOIN (
        SELECT ws_customer_id, SUM(ws_quantity) AS web_qty
        FROM web_sales
        GROUP BY ws_customer_id
    ) wb ON wb.ws_customer_id = c.c_customer_id
)
SELECT
    b.c_customer_id,
    b.c_name,
    st.s_store_name,
    b.store_qty,
    t.total_qty
FROM best_store_per_cust b
JOIN stores st
    ON b.ss_store_id = st.s_store_id
JOIN total_per_cust t
    ON t.c_customer_id = b.c_customer_id
ORDER BY t.total_qty DESC
LIMIT 5
