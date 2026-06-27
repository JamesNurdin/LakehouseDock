WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        s.s_store_name,
        i.i_price * ss.ss_quantity AS revenue,
        ss.ss_quantity AS quantity,
        c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
online_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        CAST('Online' AS varchar) AS s_store_name,
        i.i_price * ws.ws_quantity AS revenue,
        ws.ws_quantity AS quantity,
        c.c_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
all_sales AS (
    SELECT i_category_id, i_category_name, s_store_name, revenue, quantity, customer_id FROM store_sales_agg
    UNION ALL
    SELECT i_category_id, i_category_name, s_store_name, revenue, quantity, customer_id FROM online_sales_agg
),
category_sales AS (
    SELECT
        i_category_id,
        i_category_name,
        s_store_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM all_sales
    GROUP BY i_category_id, i_category_name, s_store_name
),
category_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.s_store_name,
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cr.avg_rating,
    cr.review_count,
    cs.distinct_customers
FROM category_sales cs
LEFT JOIN category_reviews cr
    ON cs.i_category_id = cr.i_category_id
    AND cs.i_category_name = cr.i_category_name
ORDER BY cs.total_revenue DESC
LIMIT 20
