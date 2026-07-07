WITH store_sales_joined AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web_sales_joined AS (
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
sales_union AS (
    SELECT item_id, quantity, customer_id FROM store_sales_joined
    UNION ALL
    SELECT item_id, quantity, customer_id FROM web_sales_joined
),
category_sales AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           SUM(s.quantity) AS total_quantity,
           SUM(s.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales_union s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
review_per_item AS (
    SELECT pr.pr_item_id AS item_id,
           SUM(pr.pr_sentiment) AS sum_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
category_review AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           SUM(r.sum_sentiment) AS total_sentiment,
           SUM(r.review_count) AS total_review_count
    FROM review_per_item r
    JOIN items i ON r.item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT cs.category,
       cs.category_id,
       cs.total_quantity AS total_quantity_sold,
       cs.total_revenue,
       cs.distinct_customers,
       CASE WHEN cr.total_review_count > 0 THEN cr.total_sentiment / cr.total_review_count ELSE NULL END AS avg_category_sentiment,
       cr.total_review_count AS total_review_count
FROM category_sales cs
LEFT JOIN category_review cr
    ON cs.category = cr.category
    AND cs.category_id = cr.category_id
ORDER BY cs.total_quantity DESC
LIMIT 10
