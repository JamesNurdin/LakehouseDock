WITH sales_union AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_customer_id AS customer_id,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
category_sales AS (
    SELECT
        su.i_category_id,
        su.i_category_name,
        SUM(su.quantity) AS total_quantity,
        SUM(su.quantity * su.price) AS total_revenue,
        COUNT(DISTINCT su.customer_id) AS distinct_customers
    FROM sales_union su
    GROUP BY su.i_category_id, su.i_category_name
),
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_category_rating,
        COUNT(pr.pr_review_id) AS total_reviews
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cs.distinct_customers,
    cr.avg_category_rating,
    cr.total_reviews
FROM category_sales cs
LEFT JOIN category_ratings cr
    ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_revenue DESC
