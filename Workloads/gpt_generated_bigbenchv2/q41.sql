WITH combined_sales AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id   AS item_id,
           ss.ss_quantity  AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id   AS item_id,
           ws.ws_quantity  AS quantity
    FROM web_sales ws
),
item_avg_rating AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(cs.quantity)                     AS total_quantity,
       SUM(cs.quantity * i.i_price)          AS total_spent,
       COUNT(DISTINCT cs.item_id)            AS distinct_items,
       AVG(ia.avg_rating)                    AS avg_item_rating
FROM combined_sales cs
JOIN customers c ON cs.customer_id = c.c_customer_id
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN item_avg_rating ia ON i.i_item_id = ia.item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spent DESC
LIMIT 20
