WITH store_sales_enriched AS (
    SELECT
        ss.ss_customer_id      AS customer_id,
        c.c_name               AS customer_name,
        ss.ss_store_id         AS store_id,
        s.s_store_name         AS store_name,
        ss.ss_item_id          AS item_id,
        i.i_name               AS item_name,
        i.i_category_name      AS category_name,
        ss.ss_quantity         AS quantity,
        i.i_price              AS price,
        ss.ss_quantity * i.i_price AS revenue,
        'store'                AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i      ON ss.ss_item_id    = i.i_item_id
    JOIN stores s     ON ss.ss_store_id   = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_customer_id      AS customer_id,
        c.c_name               AS customer_name,
        NULL                   AS store_id,
        NULL                   AS store_name,
        ws.ws_item_id          AS item_id,
        i.i_name               AS item_name,
        i.i_category_name      AS category_name,
        ws.ws_quantity         AS quantity,
        i.i_price              AS price,
        ws.ws_quantity * i.i_price AS revenue,
        'web'                  AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i      ON ws.ws_item_id    = i.i_item_id
)
SELECT
    channel,
    COALESCE(store_name, 'Online') AS location,
    category_name,
    SUM(revenue)                AS total_revenue,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    SUM(quantity)               AS total_quantity
FROM (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
) AS unified_sales
GROUP BY
    channel,
    COALESCE(store_name, 'Online'),
    category_name
ORDER BY total_revenue DESC
LIMIT 20
