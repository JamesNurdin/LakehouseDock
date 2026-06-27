WITH
    item_avg_rating AS (
        SELECT i.i_item_id AS item_id,
               AVG(pr.pr_rating) AS avg_rating,
               COUNT(*) AS review_count
        FROM items i
        JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    store_sales_detail AS (
        SELECT ss.ss_customer_id AS customer_id,
               ss.ss_item_id AS item_id,
               SUM(ss.ss_quantity) AS quantity,
               SUM(ss.ss_quantity * i.i_price) AS spent
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_customer_id, ss.ss_item_id
    ),
    web_sales_detail AS (
        SELECT ws.ws_customer_id AS customer_id,
               ws.ws_item_id AS item_id,
               SUM(ws.ws_quantity) AS quantity,
               SUM(ws.ws_quantity * i.i_price) AS spent
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_customer_id, ws.ws_item_id
    ),
    combined_sales AS (
        SELECT customer_id,
               item_id,
               quantity,
               spent
        FROM store_sales_detail
        UNION ALL
        SELECT customer_id,
               item_id,
               quantity,
               spent
        FROM web_sales_detail
    ),
    customer_aggregates AS (
        SELECT cs.customer_id,
               COUNT(DISTINCT cs.item_id) AS distinct_items,
               SUM(cs.quantity) AS total_quantity,
               SUM(cs.spent) AS total_spent,
               SUM(cs.quantity * COALESCE(r.avg_rating, 0)) / NULLIF(SUM(cs.quantity), 0) AS weighted_avg_rating
        FROM combined_sales cs
        LEFT JOIN item_avg_rating r ON cs.item_id = r.item_id
        GROUP BY cs.customer_id
    )
SELECT c.c_customer_id,
       c.c_name,
       ca.distinct_items,
       ca.total_quantity,
       ca.total_spent,
       ca.weighted_avg_rating
FROM customer_aggregates ca
JOIN customers c ON ca.customer_id = c.c_customer_id
ORDER BY ca.total_spent DESC
LIMIT 100
