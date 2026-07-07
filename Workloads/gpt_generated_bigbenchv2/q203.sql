WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
    AVG(r.avg_sentiment) AS avg_sentiment,
    SUM(r.review_count) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
WHERE i.i_category IS NOT NULL
GROUP BY i.i_category
ORDER BY total_revenue DESC
LIMIT 5
