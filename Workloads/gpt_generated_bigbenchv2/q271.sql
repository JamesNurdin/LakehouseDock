WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(ss.store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_sentiment
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
