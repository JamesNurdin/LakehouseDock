WITH store_sales_enriched AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category,
        i.i_category_id,
        s.s_store_name,
        ss.ss_quantity AS quantity,
        i.i_price * ss.ss_quantity AS revenue,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category,
        i.i_category_id,
        CAST(NULL AS varchar) AS s_store_name,
        ws.ws_quantity AS quantity,
        i.i_price * ws.ws_quantity AS revenue,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    c_name,
    i_category,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT CASE WHEN sales_channel = 'store' THEN s_store_name END) AS distinct_store_count,
    SUM(CASE WHEN sales_channel = 'store' THEN quantity END) AS store_quantity,
    SUM(CASE WHEN sales_channel = 'web' THEN quantity END) AS web_quantity
FROM (
    SELECT
        c_customer_id,
        c_name,
        i_category,
        i_category_id,
        s_store_name,
        quantity,
        revenue,
        sales_channel
    FROM store_sales_enriched
    UNION ALL
    SELECT
        c_customer_id,
        c_name,
        i_category,
        i_category_id,
        s_store_name,
        quantity,
        revenue,
        sales_channel
    FROM web_sales_enriched
) AS combined
GROUP BY c_name, i_category
ORDER BY SUM(revenue) DESC
LIMIT 100
