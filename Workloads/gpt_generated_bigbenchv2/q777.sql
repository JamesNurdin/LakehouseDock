WITH sales_union AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_item_id,
        i.i_category_name,
        i.i_price,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id

    UNION ALL

    SELECT
        CAST(NULL AS bigint) AS store_id,
        i.i_item_id,
        i.i_category_name,
        i.i_price,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),

rating_agg AS (
    SELECT
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)

SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    su.i_category_name,
    SUM(su.quantity) AS total_quantity_sold,
    SUM(su.quantity * su.i_price) AS total_revenue,
    COUNT(DISTINCT su.customer_id) AS distinct_customers,
    ra.avg_rating,
    ra.review_count
FROM sales_union su
LEFT JOIN stores s ON su.store_id = s.s_store_id
LEFT JOIN rating_agg ra ON su.i_category_name = ra.i_category_name
GROUP BY
    COALESCE(s.s_store_name, 'Online'),
    su.i_category_name,
    ra.avg_rating,
    ra.review_count
ORDER BY
    store_name,
    total_revenue DESC
