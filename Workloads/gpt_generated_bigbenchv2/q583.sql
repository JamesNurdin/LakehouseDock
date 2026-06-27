WITH store_sales_enriched AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ss.ss_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        NULL AS ss_store_id,
        NULL AS s_store_name,
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    us.c_customer_id,
    us.c_name,
    us.i_category_id,
    us.i_category_name,
    SUM(us.quantity) AS total_quantity,
    SUM(us.i_price * us.quantity) AS total_spent,
    COUNT(DISTINCT us.channel) AS channels_used
FROM (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
) us
GROUP BY
    us.c_customer_id,
    us.c_name,
    us.i_category_id,
    us.i_category_name
ORDER BY total_spent DESC
LIMIT 10
