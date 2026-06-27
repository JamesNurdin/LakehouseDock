WITH store_customer_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
),
web_customer_sales AS (
    SELECT
        ws.ws_customer_id,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_customer_id
),
combined_sales AS (
    SELECT
        scs.ss_store_id,
        scs.ss_customer_id,
        scs.store_qty,
        COALESCE(wcs.web_qty, 0) AS web_qty,
        scs.store_qty + COALESCE(wcs.web_qty, 0) AS total_qty
    FROM store_customer_sales scs
    LEFT JOIN web_customer_sales wcs
        ON scs.ss_customer_id = wcs.ws_customer_id
),
ranked_customers AS (
    SELECT
        cs.ss_store_id,
        cs.ss_customer_id,
        cs.store_qty,
        cs.web_qty,
        cs.total_qty,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_qty DESC) AS rn
    FROM combined_sales cs
)
SELECT
    s.s_store_name,
    c.c_name,
    rc.store_qty,
    rc.web_qty,
    rc.total_qty
FROM ranked_customers rc
JOIN stores s
    ON rc.ss_store_id = s.s_store_id
JOIN customers c
    ON rc.ss_customer_id = c.c_customer_id
WHERE rc.rn <= 5
ORDER BY s.s_store_name, rc.total_qty DESC
