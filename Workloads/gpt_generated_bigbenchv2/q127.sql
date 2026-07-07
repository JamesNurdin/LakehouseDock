WITH unified_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_customer_id AS customer_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_customer_id AS customer_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
item_reviews AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(us.quantity) AS total_quantity,
    SUM(us.quantity * us.price) AS total_revenue,
    COUNT(DISTINCT us.customer_id) AS distinct_customers,
    AVG(ir.avg_sentiment) AS avg_sentiment
FROM unified_sales us
JOIN items i ON us.item_id = i.i_item_id
LEFT JOIN item_reviews ir ON i.i_item_id = ir.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
