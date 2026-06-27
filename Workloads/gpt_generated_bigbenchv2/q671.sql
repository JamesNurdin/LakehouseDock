WITH store_purchases AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           s.s_store_id AS store_id
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_purchases AS (
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           CAST(NULL AS BIGINT) AS store_id
    FROM web_sales ws
),
all_purchases AS (
    SELECT customer_id, item_id, quantity, store_id FROM store_purchases
    UNION ALL
    SELECT customer_id, item_id, quantity, store_id FROM web_purchases
),
item_info AS (
    SELECT i.i_item_id AS item_id,
           i.i_price,
           i.i_category_id,
           i.i_category_name
    FROM items i
),
item_ratings AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
purchases_enriched AS (
    SELECT ap.customer_id,
           ap.item_id,
           ap.quantity,
           ap.store_id,
           ii.i_price,
           ii.i_category_id,
           ii.i_category_name,
           ir.avg_rating
    FROM all_purchases ap
    JOIN item_info ii ON ap.item_id = ii.item_id
    LEFT JOIN item_ratings ir ON ap.item_id = ir.item_id
),
customer_summary AS (
    SELECT pe.customer_id,
           SUM(pe.quantity) AS total_quantity,
           COUNT(DISTINCT pe.store_id) AS distinct_store_count,
           SUM(pe.i_price * pe.quantity) / NULLIF(SUM(pe.quantity), 0) AS avg_price,
           SUM(COALESCE(pe.avg_rating, 0) * pe.quantity) / NULLIF(SUM(CASE WHEN pe.avg_rating IS NOT NULL THEN pe.quantity END), 0) AS avg_rating
    FROM purchases_enriched pe
    GROUP BY pe.customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       cs.total_quantity,
       cs.distinct_store_count,
       cs.avg_price,
       cs.avg_rating
FROM customer_summary cs
JOIN customers c ON cs.customer_id = c.c_customer_id
ORDER BY cs.total_quantity DESC
LIMIT 10
