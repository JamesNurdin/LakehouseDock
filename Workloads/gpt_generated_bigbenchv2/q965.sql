WITH store_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count,
        COUNT(DISTINCT ss.ss_store_id) AS store_count
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
rating_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
distinct_customers AS (
    SELECT
        item_id,
        COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM (
        SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
        FROM web_sales ws
    )
    GROUP BY item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(dc.distinct_customer_count, 0) AS distinct_customer_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(sa.store_count, 0) AS store_count
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN rating_agg r ON r.pr_item_id = i.i_item_id
LEFT JOIN distinct_customers dc ON dc.item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
