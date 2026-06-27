WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_purchases AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id    AS item_id,
           ss.ss_quantity   AS quantity,
           i.i_price        AS price,
           ir.avg_rating,
           ir.review_count,
           'store'          AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web_purchases AS (
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id    AS item_id,
           ws.ws_quantity   AS quantity,
           i.i_price        AS price,
           ir.avg_rating,
           ir.review_count,
           'web'            AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
all_purchases AS (
    SELECT * FROM store_purchases
    UNION ALL
    SELECT * FROM web_purchases
)
SELECT c.c_name                         AS customer_name,
       SUM(ap.quantity)                 AS total_quantity,
       SUM(ap.quantity * ap.price)      AS total_spent,
       COUNT(DISTINCT ap.item_id)       AS distinct_items,
       AVG(ap.avg_rating)               AS avg_item_rating,
       SUM(COALESCE(ap.review_count, 0)) AS total_reviews,
       SUM(CASE WHEN ap.channel = 'store' THEN ap.quantity ELSE 0 END) AS store_quantity,
       SUM(CASE WHEN ap.channel = 'web'   THEN ap.quantity ELSE 0 END) AS web_quantity
FROM all_purchases ap
JOIN customers c ON ap.customer_id = c.c_customer_id
GROUP BY c.c_name
ORDER BY total_spent DESC
LIMIT 10
