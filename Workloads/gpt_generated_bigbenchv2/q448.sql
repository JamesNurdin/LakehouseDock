WITH store_sales_enriched AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        c.c_name AS customer_name,
        ss.ss_store_id AS store_id,
        s.s_store_name AS store_name,
        ss.ss_item_id AS item_id,
        i.i_category AS category,
        i.i_category_id AS category_id,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        c.c_name AS customer_name,
        NULL AS store_id,
        NULL AS store_name,
        ws.ws_item_id AS item_id,
        i.i_category AS category,
        i.i_category_id AS category_id,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT
        customer_id,
        customer_name,
        store_id,
        store_name,
        item_id,
        category,
        category_id,
        quantity,
        revenue,
        sales_channel
    FROM store_sales_enriched
    UNION ALL
    SELECT
        customer_id,
        customer_name,
        store_id,
        store_name,
        item_id,
        category,
        category_id,
        quantity,
        revenue,
        sales_channel
    FROM web_sales_enriched
)
SELECT
    cs.customer_id,
    cs.customer_name,
    cs.category,
    cs.category_id,
    cs.sales_channel,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.revenue) AS total_revenue
FROM combined_sales cs
GROUP BY cs.customer_id, cs.customer_name, cs.category, cs.category_id, cs.sales_channel
ORDER BY total_revenue DESC
LIMIT 100
