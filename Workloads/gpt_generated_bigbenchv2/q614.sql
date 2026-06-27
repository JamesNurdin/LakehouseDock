WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_combined AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_quantity AS quantity,
           ss.ss_quantity * i.i_price AS spend,
           COALESCE(ir.avg_rating, 0) AS rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_quantity AS quantity,
           ws.ws_quantity * i.i_price AS spend,
           COALESCE(ir.avg_rating, 0) AS rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(s.quantity) AS total_quantity,
       SUM(s.spend) AS total_spend,
       CASE WHEN SUM(s.quantity) > 0 THEN SUM(s.rating * s.quantity) / SUM(s.quantity) ELSE NULL END AS avg_item_rating
FROM sales_combined s
JOIN customers c ON s.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 20
