WITH rating_by_item AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_by_store AS (
    SELECT
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price,
        ss.ss_customer_id,
        i.i_category_name,
        s.s_store_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_by_store AS (
    SELECT
        ws.ws_item_id,
        ws.ws_quantity,
        i.i_price,
        ws.ws_customer_id,
        i.i_category_name,
        'Online' AS s_store_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    s_store_name,
    i_category_name,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_revenue) AS total_revenue,
    AVG(avg_rating) AS avg_item_rating,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM (
    SELECT
        s_store_name,
        i_category_name,
        ss_quantity AS total_quantity,
        ss_quantity * i_price AS total_revenue,
        r.avg_rating,
        ss.ss_customer_id AS customer_id
    FROM store_sales_by_store ss
    LEFT JOIN rating_by_item r ON ss.ss_item_id = r.i_item_id
    UNION ALL
    SELECT
        s_store_name,
        i_category_name,
        ws_quantity AS total_quantity,
        ws_quantity * i_price AS total_revenue,
        r.avg_rating,
        ws.ws_customer_id AS customer_id
    FROM web_sales_by_store ws
    LEFT JOIN rating_by_item r ON ws.ws_item_id = r.i_item_id
) AS combined
GROUP BY s_store_name, i_category_name
ORDER BY total_revenue DESC
