WITH item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(CAST(pr.pr_rating AS double)) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_customer_id AS customer_id,
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        NULL AS store_id,
        ws.ws_customer_id AS customer_id,
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    COALESCE(stores.s_store_name, 'Online') AS store_name,
    sales.i_category_name AS category_name,
    SUM(sales.quantity) AS total_quantity,
    SUM(sales.quantity * sales.price) AS total_revenue,
    COUNT(DISTINCT sales.customer_id) AS distinct_customers,
    AVG(item_reviews.avg_rating) AS avg_item_rating,
    SUM(item_reviews.review_count) AS total_reviews
FROM sales
LEFT JOIN stores ON sales.store_id = stores.s_store_id
LEFT JOIN item_reviews ON sales.i_item_id = item_reviews.i_item_id
GROUP BY
    COALESCE(stores.s_store_name, 'Online'),
    sales.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
