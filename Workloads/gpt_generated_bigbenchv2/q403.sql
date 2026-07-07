WITH store_sales_enriched AS (
    SELECT
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        i.i_category AS category,
        s.s_store_name AS store_name
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        i.i_category AS category,
        CAST('Online' AS varchar) AS store_name
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    all_sales.category,
    all_sales.store_name,
    SUM(all_sales.quantity) AS total_quantity,
    SUM(all_sales.quantity * all_sales.price) AS total_revenue
FROM (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
) AS all_sales
GROUP BY all_sales.category, all_sales.store_name
ORDER BY total_revenue DESC
