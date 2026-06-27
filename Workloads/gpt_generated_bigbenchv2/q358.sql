WITH item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_enriched AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        ss.ss_quantity * i.i_price AS revenue,
        ir.avg_rating AS item_rating
    FROM store_sales ss
    JOIN items i ON i.i_item_id = ss.ss_item_id
    LEFT JOIN item_ratings ir ON ir.item_id = ss.ss_item_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        NULL AS store_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        ws.ws_quantity * i.i_price AS revenue,
        ir.avg_rating AS item_rating
    FROM web_sales ws
    JOIN items i ON i.i_item_id = ws.ws_item_id
    LEFT JOIN item_ratings ir ON ir.item_id = ws.ws_item_id
),
combined_sales AS (
    SELECT
        customer_id,
        store_id,
        item_id,
        quantity,
        price,
        revenue,
        item_rating
    FROM store_sales_enriched
    UNION ALL
    SELECT
        customer_id,
        store_id,
        item_id,
        quantity,
        price,
        revenue,
        item_rating
    FROM web_sales_enriched
),
customer_sales AS (
    SELECT
        cs.customer_id,
        SUM(cs.revenue) AS total_revenue,
        SUM(cs.quantity) AS total_quantity,
        AVG(cs.item_rating) FILTER (WHERE cs.item_rating IS NOT NULL) AS avg_item_rating,
        COUNT(DISTINCT cs.store_id) FILTER (WHERE cs.store_id IS NOT NULL) AS distinct_stores_visited
    FROM combined_sales cs
    GROUP BY cs.customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cs.total_revenue,
    cs.total_quantity,
    cs.avg_item_rating,
    cs.distinct_stores_visited
FROM customers c
JOIN customer_sales cs ON cs.customer_id = c.c_customer_id
ORDER BY cs.total_revenue DESC
LIMIT 20
