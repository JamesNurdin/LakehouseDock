WITH store_sales_enriched AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity,
        i.i_price,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_enriched AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity,
        i.i_price,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT
        c_customer_id,
        c_name,
        i_category_id,
        i_category_name,
        ss_quantity AS quantity,
        revenue
    FROM store_sales_enriched
    UNION ALL
    SELECT
        c_customer_id,
        c_name,
        i_category_id,
        i_category_name,
        ws_quantity AS quantity,
        revenue
    FROM web_sales_enriched
)
SELECT
    c_customer_id,
    c_name,
    i_category_name,
    total_quantity,
    total_revenue,
    avg_price_per_item,
    RANK() OVER (PARTITION BY i_category_name ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT
        c_customer_id,
        c_name,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        AVG(revenue / NULLIF(quantity, 0)) AS avg_price_per_item
    FROM combined_sales
    GROUP BY c_customer_id, c_name, i_category_name
) agg_by_customer_category
ORDER BY total_revenue DESC
LIMIT 100
