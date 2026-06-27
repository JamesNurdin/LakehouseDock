SELECT
    combined.i_category_id,
    combined.i_category_name,
    SUM(combined.total_quantity) AS total_quantity,
    SUM(combined.total_revenue) AS total_revenue,
    AVG(combined.avg_rating) AS avg_rating,
    COUNT(DISTINCT combined.customer_id) AS distinct_customers,
    COUNT(DISTINCT combined.store_id) AS distinct_stores
FROM (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS total_quantity,
        ss.ss_quantity * i.i_price AS total_revenue,
        CAST(NULL AS integer) AS avg_rating,
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS total_quantity,
        ws.ws_quantity * i.i_price AS total_revenue,
        CAST(NULL AS integer) AS avg_rating,
        ws.ws_customer_id AS customer_id,
        CAST(NULL AS bigint) AS store_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id

    UNION ALL

    SELECT
        i.i_category_id,
        i.i_category_name,
        0 AS total_quantity,
        CAST(0 AS decimal(7,2)) AS total_revenue,
        pr.pr_rating AS avg_rating,
        CAST(NULL AS bigint) AS customer_id,
        CAST(NULL AS bigint) AS store_id
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
) AS combined
GROUP BY
    combined.i_category_id,
    combined.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
