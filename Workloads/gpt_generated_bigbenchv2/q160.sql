WITH sales_all AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    UNION ALL
    SELECT
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        ws.ws_customer_id AS customer_id,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.i_category_id,
    s.i_category_name,
    SUM(s.quantity) FILTER (WHERE s.channel = 'store') AS total_store_quantity,
    SUM(s.quantity) FILTER (WHERE s.channel = 'web') AS total_web_quantity,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * s.price) FILTER (WHERE s.channel = 'store') AS total_store_revenue,
    SUM(s.quantity * s.price) FILTER (WHERE s.channel = 'web') AS total_web_revenue,
    SUM(s.quantity * s.price) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS distinct_customer_count,
    COUNT(DISTINCT s.store_id) FILTER (WHERE s.channel = 'store') AS distinct_store_count,
    MAX(r.avg_rating) AS avg_rating
FROM sales_all s
LEFT JOIN reviews_agg r
    ON s.i_category_id = r.i_category_id
    AND s.i_category_name = r.i_category_name
GROUP BY s.i_category_id, s.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
