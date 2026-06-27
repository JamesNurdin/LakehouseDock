WITH combined_sales AS (
    -- Store channel sales
    SELECT
        s.s_store_name AS channel_or_store,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id

    UNION ALL

    -- Web channel sales
    SELECT
        'Web' AS channel_or_store,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
aggregated AS (
    SELECT
        channel_or_store,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        ROUND(SUM(revenue) / NULLIF(SUM(quantity), 0), 2) AS avg_price,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM combined_sales
    GROUP BY channel_or_store, i_category_name
),
final AS (
    SELECT
        channel_or_store,
        i_category_name,
        total_quantity,
        total_revenue,
        avg_price,
        distinct_customers,
        ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 2) AS revenue_pct
    FROM aggregated
)
SELECT
    channel_or_store,
    i_category_name,
    total_quantity,
    total_revenue,
    avg_price,
    distinct_customers,
    revenue_pct
FROM final
ORDER BY total_revenue DESC
LIMIT 20
