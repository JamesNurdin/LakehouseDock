WITH store_item_rev AS (
    SELECT
        ss.ss_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        ss.ss_item_id AS i_item_id,
        i.i_name AS i_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_item_id,
        i.i_name
),
web_item_rev AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
store_item_with_web AS (
    SELECT
        si.s_store_id,
        si.s_store_name,
        si.i_item_id,
        si.i_name,
        si.store_quantity,
        si.store_revenue,
        COALESCE(wi.web_quantity, 0) AS web_quantity,
        COALESCE(wi.web_revenue, 0) AS web_revenue,
        ROW_NUMBER() OVER (PARTITION BY si.s_store_id ORDER BY si.store_revenue DESC) AS rn
    FROM store_item_rev si
    LEFT JOIN web_item_rev wi
        ON si.i_item_id = wi.i_item_id
)
SELECT
    s_store_id,
    s_store_name,
    i_item_id,
    i_name,
    store_quantity,
    store_revenue,
    web_quantity,
    web_revenue
FROM store_item_with_web
WHERE rn <= 5
ORDER BY s_store_id, rn
