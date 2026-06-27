WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_purchases AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        ss.ss_item_id AS i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ir.avg_rating AS avg_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
),
web_purchases AS (
    SELECT
        ws.ws_customer_id AS c_customer_id,
        ws.ws_item_id AS i_item_id,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        ir.avg_rating AS avg_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
),
combined_purchases AS (
    SELECT c_customer_id, i_item_id, quantity, revenue, avg_rating FROM store_purchases
    UNION ALL
    SELECT c_customer_id, i_item_id, quantity, revenue, avg_rating FROM web_purchases
),
customer_agg AS (
    SELECT
        c_customer_id,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_spend,
        CASE WHEN SUM(quantity) > 0 THEN SUM(quantity * avg_rating) / SUM(quantity) ELSE NULL END AS weighted_avg_rating,
        COUNT(DISTINCT i_item_id) AS distinct_items,
        COUNT(DISTINCT CASE WHEN avg_rating IS NOT NULL THEN i_item_id END) AS items_with_reviews
    FROM combined_purchases
    GROUP BY c_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    ca.total_quantity,
    ca.total_spend,
    ca.weighted_avg_rating,
    ca.distinct_items,
    ca.items_with_reviews
FROM customers c
JOIN customer_agg ca ON c.c_customer_id = ca.c_customer_id
ORDER BY ca.total_spend DESC
LIMIT 50
