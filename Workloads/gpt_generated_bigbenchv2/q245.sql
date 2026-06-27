WITH store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
rating_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity_sold,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(sa.store_customer_cnt, 0) + COALESCE(wa.web_customer_cnt, 0) AS total_distinct_customers_est,
    ra.avg_rating,
    ra.review_cnt
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.i_item_id
WHERE COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) > 0
ORDER BY total_quantity_sold DESC
LIMIT 10
