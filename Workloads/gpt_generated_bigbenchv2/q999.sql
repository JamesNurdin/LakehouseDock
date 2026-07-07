WITH purchased_items AS (
    SELECT ss.ss_customer_id AS c_customer_id,
           ss.ss_item_id AS i_item_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_customer_id AS c_customer_id,
           ws.ws_item_id AS i_item_id
    FROM web_sales ws
),
customer_reviews AS (
    SELECT pi.c_customer_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM purchased_items pi
    JOIN product_reviews pr ON pr.pr_item_id = pi.i_item_id
    GROUP BY pi.c_customer_id
),
store_agg AS (
    SELECT c.c_customer_id,
           SUM(ss.ss_quantity * i.i_price) AS store_spend,
           SUM(ss.ss_quantity) AS store_quantity
    FROM customers c
    JOIN store_sales ss ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY c.c_customer_id
),
web_agg AS (
    SELECT c.c_customer_id,
           SUM(ws.ws_quantity * i.i_price) AS web_spend,
           SUM(ws.ws_quantity) AS web_quantity
    FROM customers c
    JOIN web_sales ws ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY c.c_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       COALESCE(sa.store_spend, 0) + COALESCE(wa.web_spend, 0) AS total_spend,
       COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
       cr.avg_sentiment
FROM customers c
LEFT JOIN store_agg sa ON sa.c_customer_id = c.c_customer_id
LEFT JOIN web_agg wa ON wa.c_customer_id = c.c_customer_id
LEFT JOIN customer_reviews cr ON cr.c_customer_id = c.c_customer_id
ORDER BY total_spend DESC
LIMIT 100
