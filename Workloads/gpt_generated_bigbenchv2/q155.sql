WITH sales_union AS (
    SELECT ss.ss_customer_id AS c_customer_id,
           c.c_name,
           ss.ss_item_id AS i_item_id,
           i.i_price,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_customer_id AS c_customer_id,
           c.c_name,
           ws.ws_item_id AS i_item_id,
           i.i_price,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_ratings AS (
    SELECT i.i_item_id AS i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT su.c_customer_id,
       su.c_name,
       SUM(su.quantity) AS total_quantity,
       SUM(su.i_price * su.quantity) AS total_spend,
       SUM(su.quantity * ir.avg_rating) / SUM(su.quantity) AS weighted_avg_rating
FROM sales_union su
JOIN item_ratings ir ON su.i_item_id = ir.i_item_id
GROUP BY su.c_customer_id, su.c_name
ORDER BY total_spend DESC
LIMIT 10
