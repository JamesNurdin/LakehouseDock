WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
    HAVING COUNT(pr.pr_review_id) > 0
),
store_sales_flat AS (
    SELECT ss.ss_customer_id AS c_customer_id,
           ss.ss_item_id AS i_item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
),
web_sales_flat AS (
    SELECT ws.ws_customer_id AS c_customer_id,
           ws.ws_item_id AS i_item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),
combined_sales AS (
    SELECT c_customer_id, i_item_id, quantity FROM store_sales_flat
    UNION ALL
    SELECT c_customer_id, i_item_id, quantity FROM web_sales_flat
),
customer_sales AS (
    SELECT cs.c_customer_id,
           SUM(cs.quantity) AS total_quantity,
           SUM(cs.quantity * i.i_price) AS total_spend,
           AVG(ir.avg_rating) AS avg_item_rating,
           COUNT(DISTINCT cs.i_item_id) AS distinct_items
    FROM combined_sales cs
    JOIN items i
        ON i.i_item_id = cs.i_item_id
    LEFT JOIN item_ratings ir
        ON ir.i_item_id = i.i_item_id
    GROUP BY cs.c_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       cs.total_quantity,
       cs.total_spend,
       cs.avg_item_rating,
       cs.distinct_items
FROM customer_sales cs
JOIN customers c
    ON c.c_customer_id = cs.c_customer_id
ORDER BY cs.total_spend DESC
LIMIT 20
