WITH sales_union AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        c.c_name AS customer_name,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        c.c_name AS customer_name,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_sales AS (
    SELECT
        customer_id,
        customer_name,
        category_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT channel) AS channel_count
    FROM sales_union
    GROUP BY
        customer_id,
        customer_name,
        category_name
),
ranked_categories AS (
    SELECT
        customer_id,
        customer_name,
        category_name,
        total_quantity,
        total_revenue,
        channel_count,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_revenue DESC) AS category_rank
    FROM category_sales
)
SELECT
    customer_id,
    customer_name,
    category_name,
    total_quantity,
    total_revenue,
    channel_count
FROM ranked_categories
WHERE category_rank <= 3
ORDER BY total_revenue DESC
