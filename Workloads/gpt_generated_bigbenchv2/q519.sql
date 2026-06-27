-- Analytical query: total purchases and average review rating per customer
WITH store_agg AS (
    SELECT
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS store_total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_total_spend,
        COUNT(DISTINCT ss.ss_item_id) AS store_distinct_items,
        AVG(pr.pr_rating) FILTER (WHERE pr.pr_rating IS NOT NULL) AS avg_item_rating_store
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    GROUP BY ss.ss_customer_id
),
web_agg AS (
    SELECT
        ws.ws_customer_id,
        SUM(ws.ws_quantity) AS web_total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_total_spend,
        COUNT(DISTINCT ws.ws_item_id) AS web_distinct_items,
        AVG(pr.pr_rating) FILTER (WHERE pr.pr_rating IS NOT NULL) AS avg_item_rating_web
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    GROUP BY ws.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sa.store_total_quantity, 0) AS total_store_quantity,
    COALESCE(wa.web_total_quantity, 0) AS total_web_quantity,
    COALESCE(sa.store_total_spend, 0) + COALESCE(wa.web_total_spend, 0) AS total_spend,
    COALESCE(sa.store_distinct_items, 0) + COALESCE(wa.web_distinct_items, 0) AS total_distinct_items,
    CASE
        WHEN (sa.avg_item_rating_store IS NULL AND wa.avg_item_rating_web IS NULL) THEN NULL
        WHEN sa.avg_item_rating_store IS NULL THEN wa.avg_item_rating_web
        WHEN wa.avg_item_rating_web IS NULL THEN sa.avg_item_rating_store
        ELSE (sa.avg_item_rating_store + wa.avg_item_rating_web) / 2.0
    END AS avg_item_rating
FROM customers c
LEFT JOIN store_agg sa ON c.c_customer_id = sa.ss_customer_id
LEFT JOIN web_agg wa ON c.c_customer_id = wa.ws_customer_id
ORDER BY total_spend DESC
LIMIT 100
