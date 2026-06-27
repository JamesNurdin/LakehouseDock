WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales_union AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id AS category_id,
           i.i_category_name AS category_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id AS category_id,
           i.i_category_name AS category_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT c.c_customer_id,
       c.c_name,
       su.category_id,
       su.category_name,
       SUM(su.quantity * su.price) AS total_spent,
       SUM(su.quantity) AS total_quantity,
       AVG(r.avg_rating) AS avg_item_rating
FROM sales_union su
JOIN customers c ON su.customer_id = c.c_customer_id
LEFT JOIN item_avg_rating r ON su.item_id = r.i_item_id
GROUP BY c.c_customer_id, c.c_name, su.category_id, su.category_name
ORDER BY total_spent DESC
LIMIT 10
