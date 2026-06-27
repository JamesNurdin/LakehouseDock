WITH item_avg_rating AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_item_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_purchases AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        i.i_item_id AS item_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_purchases AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        CAST(NULL AS bigint) AS store_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        i.i_item_id AS item_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_purchases AS (
    SELECT
        customer_id,
        store_id,
        quantity,
        price,
        item_id
    FROM store_purchases
    UNION ALL
    SELECT
        customer_id,
        store_id,
        quantity,
        price,
        item_id
    FROM web_purchases
)
SELECT
    c.c_customer_id,
    c.c_name,
    COUNT(DISTINCT ap.store_id) AS distinct_stores_visited,
    SUM(ap.quantity) AS total_quantity,
    SUM(ap.quantity * ap.price) AS total_spent,
    SUM(ap.quantity * ir.avg_item_rating) / NULLIF(SUM(CASE WHEN ir.avg_item_rating IS NOT NULL THEN ap.quantity END), 0) AS avg_rating_of_purchased_items
FROM all_purchases ap
JOIN customers c ON ap.customer_id = c.c_customer_id
LEFT JOIN item_avg_rating ir ON ap.item_id = ir.i_item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spent DESC
LIMIT 20
