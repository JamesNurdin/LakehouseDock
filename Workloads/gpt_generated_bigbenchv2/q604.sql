WITH store_totals AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name
),
web_totals AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name
),
combined AS (
    SELECT
        COALESCE(s.c_customer_id, w.c_customer_id) AS c_customer_id,
        COALESCE(s.c_name, w.c_name) AS c_name,
        COALESCE(s.store_sales_amount, 0) AS store_sales_amount,
        COALESCE(w.web_sales_amount, 0) AS web_sales_amount,
        COALESCE(s.store_sales_amount, 0) + COALESCE(w.web_sales_amount, 0) AS total_sales_amount
    FROM store_totals s
    FULL OUTER JOIN web_totals w
        ON s.c_customer_id = w.c_customer_id
)
SELECT
    c_customer_id,
    c_name,
    store_sales_amount,
    web_sales_amount,
    total_sales_amount
FROM combined
ORDER BY total_sales_amount DESC
LIMIT 5
