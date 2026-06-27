WITH
store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
rating_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sa.total_store_revenue, CAST(0 AS decimal(7,2))) AS total_store_revenue,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wa.total_web_revenue, CAST(0 AS decimal(7,2))) AS total_web_revenue,
    COALESCE(sa.total_store_revenue, CAST(0 AS decimal(7,2))) + COALESCE(wa.total_web_revenue, CAST(0 AS decimal(7,2))) AS total_revenue,
    ra.avg_rating,
    ra.review_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 10
