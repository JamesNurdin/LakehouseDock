WITH store_sales_agg AS (
    SELECT
        CAST(ss_ts AS DATE) AS sale_date,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        i_price AS price,
        i_category_id AS category_id,
        i_category_name AS category_name,
        i_price * ss_quantity AS revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    JOIN customers ON store_sales.ss_customer_id = customers.c_customer_id
),
web_sales_agg AS (
    SELECT
        CAST(ws_ts AS DATE) AS sale_date,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        i_price AS price,
        i_category_id AS category_id,
        i_category_name AS category_name,
        i_price * ws_quantity AS revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    JOIN customers ON web_sales.ws_customer_id = customers.c_customer_id
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
review_agg AS (
    SELECT
        i.i_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    DATE_TRUNC('month', cs.sale_date) AS month,
    cs.category_name,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.revenue) AS total_revenue,
    COUNT(DISTINCT cs.customer_id) AS distinct_customers,
    AVG(ra.avg_rating) AS avg_item_rating,
    SUM(cs.revenue) / COUNT(DISTINCT cs.customer_id) AS revenue_per_customer
FROM combined_sales cs
LEFT JOIN review_agg ra ON cs.item_id = ra.item_id
GROUP BY DATE_TRUNC('month', cs.sale_date), cs.category_name
ORDER BY month DESC, total_revenue DESC
LIMIT 10
