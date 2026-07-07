WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    ss.category,
    ss.store_quantity,
    ss.store_revenue,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    COALESCE(r.avg_sentiment, NULL) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
JOIN stores s ON ss.store_id = s.s_store_id
LEFT JOIN web_sales_agg ws ON ss.category = ws.category
LEFT JOIN reviews_agg r ON ss.category = r.category
ORDER BY ss.store_revenue DESC
LIMIT 20
