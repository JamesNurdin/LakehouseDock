WITH sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           ss.ss_quantity AS quantity,
           i.i_price * ss.ss_quantity AS revenue,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id

    UNION ALL

    SELECT i.i_category_id,
           i.i_category_name,
           ws.ws_quantity AS quantity,
           i.i_price * ws.ws_quantity AS revenue,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
category_sales AS (
    SELECT i_category_id,
           i_category_name,
           SUM(quantity) AS total_quantity,
           SUM(revenue) AS total_revenue,
           COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales
    GROUP BY i_category_id, i_category_name
),
category_ratings AS (
    SELECT i.i_category_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT cs.i_category_id,
       cs.i_category_name,
       cs.total_quantity,
       cs.total_revenue,
       cs.distinct_customers,
       COALESCE(cr.avg_rating, 0) AS avg_rating
FROM category_sales cs
LEFT JOIN category_ratings cr ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_revenue DESC
LIMIT 20
