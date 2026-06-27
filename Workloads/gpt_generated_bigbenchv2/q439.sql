WITH item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
combined_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_item_id AS item_id,
        i.i_category_name AS category_name,
        i.i_price AS price,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id

    UNION ALL

    SELECT
        NULL AS store_id,
        'Online' AS store_name,
        i.i_item_id AS item_id,
        i.i_category_name AS category_name,
        i.i_price AS price,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    cs.store_name,
    cs.category_name,
    COUNT(DISTINCT cs.item_id) AS distinct_items_sold,
    SUM(cs.quantity) AS total_quantity_sold,
    SUM(cs.quantity * cs.price) AS total_revenue,
    COUNT(DISTINCT cs.customer_id) AS distinct_customers,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_reviews
FROM combined_sales cs
LEFT JOIN item_ratings ir ON ir.item_id = cs.item_id
GROUP BY
    cs.store_name,
    cs.category_name
ORDER BY total_revenue DESC
LIMIT 10
