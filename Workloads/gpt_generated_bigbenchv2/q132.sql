WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customers_union AS (
    SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
    FROM web_sales ws
),
customer_counts AS (
    SELECT item_id, COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM customers_union
    GROUP BY item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue,
    COALESCE(rc.avg_rating, 0) AS avg_rating,
    COALESCE(rc.review_count, 0) AS review_count,
    COALESCE(cc.distinct_customer_count, 0) AS distinct_customer_count
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg rc ON rc.pr_item_id = i.i_item_id
LEFT JOIN customer_counts cc ON cc.item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
