WITH review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id AS category_id,
           i.i_category AS category
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id AS category_id,
           i.i_category AS category
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT cs.category_id,
       cs.category,
       SUM(cs.quantity) AS total_quantity,
       SUM(cs.quantity * cs.price) AS total_revenue,
       AVG(ra.avg_sentiment) AS avg_category_sentiment,
       SUM(ra.review_count) AS total_reviews
FROM combined_sales cs
LEFT JOIN review_agg ra ON ra.item_id = cs.item_id
GROUP BY cs.category_id, cs.category
ORDER BY total_revenue DESC
LIMIT 10
