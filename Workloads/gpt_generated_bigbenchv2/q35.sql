WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_enriched AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id      AS item_id,
           ss.ss_quantity    AS quantity,
           i.i_price          AS price,
           ir.avg_rating     AS avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
),
web_sales_enriched AS (
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id      AS item_id,
           ws.ws_quantity    AS quantity,
           i.i_price          AS price,
           ir.avg_rating     AS avg_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
),
all_sales AS (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(s.quantity) AS total_quantity,
       SUM(s.quantity * s.price) AS total_revenue,
       AVG(s.avg_rating) AS avg_item_rating,
       COUNT(DISTINCT s.item_id) AS distinct_items_purchased
FROM all_sales s
JOIN customers c ON s.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_revenue DESC
LIMIT 20
