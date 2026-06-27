WITH store_sales_enriched AS (
    SELECT
        i.i_category_name,
        i.i_price,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    WHERE i.i_category_name = 'Electronics' AND i.i_price > 20
),
web_sales_enriched AS (
    SELECT
        i.i_category_name,
        i.i_price,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    WHERE i.i_category_name = 'Electronics' AND i.i_price > 20
),
all_sales AS (
    SELECT
        i_category_name,
        i_price,
        quantity,
        customer_id,
        sales_channel
    FROM store_sales_enriched
    UNION ALL
    SELECT
        i_category_name,
        i_price,
        quantity,
        customer_id,
        sales_channel
    FROM web_sales_enriched
)
SELECT
    i_category_name,
    sales_channel,
    SUM(quantity) AS total_quantity,
    SUM(i_price * quantity) AS total_revenue,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM all_sales
GROUP BY i_category_name, sales_channel
ORDER BY total_revenue DESC
