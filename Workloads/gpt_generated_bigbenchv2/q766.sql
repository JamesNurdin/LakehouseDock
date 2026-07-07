WITH store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(COALESCE(sa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(sa.store_revenue, 0)) AS total_store_revenue,
    SUM(COALESCE(wa.web_quantity, 0)) AS total_web_quantity,
    SUM(COALESCE(wa.web_revenue, 0)) AS total_web_revenue,
    SUM(COALESCE(ra.review_count, 0)) AS total_review_count,
    AVG(ra.avg_sentiment) AS avg_item_sentiment
FROM items i
LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_store_revenue DESC
LIMIT 10
