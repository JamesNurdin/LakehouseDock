WITH unified_sales AS (
    -- Combine store and web sales, attaching the item price for spend calculation
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id     AS item_id,
        ss.ss_quantity    AS quantity,
        ss.ss_quantity * i.i_price AS spend
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id     AS item_id,
        ws.ws_quantity    AS quantity,
        ws.ws_quantity * i.i_price AS spend
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_avg_rating AS (
    -- Average rating per item (if any reviews exist)
    SELECT
        i.i_item_id,
        avg(pr.pr_rating) AS avg_rating
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
customer_agg AS (
    -- Aggregate sales and rating information per customer
    SELECT
        u.customer_id,
        sum(u.quantity)               AS total_quantity,
        sum(u.spend)                  AS total_spend,
        count(DISTINCT u.item_id)     AS distinct_items,
        avg(iar.avg_rating)           AS avg_item_rating
    FROM unified_sales u
    LEFT JOIN item_avg_rating iar ON iar.i_item_id = u.item_id
    GROUP BY u.customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    ca.total_quantity,
    ca.total_spend,
    ca.distinct_items,
    ca.avg_item_rating
FROM customer_agg ca
JOIN customers c ON ca.customer_id = c.c_customer_id
ORDER BY ca.total_spend DESC
LIMIT 100
