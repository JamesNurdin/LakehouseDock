WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sa.total_store_revenue, 0.0) AS total_store_revenue,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wa.total_web_revenue, 0.0) AS total_web_revenue,
    COALESCE(ra.avg_sentiment, NULL) AS avg_sentiment,
    COALESCE(ra.review_count, 0) AS review_count,
    (COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0)) AS total_quantity,
    (COALESCE(sa.total_store_revenue, 0.0) + COALESCE(wa.total_web_revenue, 0.0)) AS total_revenue
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN reviews_agg ra ON i.i_item_id = ra.pr_item_id
ORDER BY total_revenue DESC
LIMIT 10
