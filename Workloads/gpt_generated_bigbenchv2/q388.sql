WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        COUNT(pr.pr_review_id) AS review_count,
        SUM(pr.pr_sentiment) AS sum_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    COALESCE(ss.i_category, ws.i_category, r.i_category) AS category,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    SUM(COALESCE(r.sum_sentiment, 0)) / NULLIF(SUM(COALESCE(r.review_count, 0)), 0) AS avg_sentiment
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.i_item_id = ws.i_item_id
FULL OUTER JOIN reviews_agg r ON COALESCE(ss.i_item_id, ws.i_item_id) = r.i_item_id
GROUP BY COALESCE(ss.i_category, ws.i_category, r.i_category)
ORDER BY total_revenue DESC
LIMIT 10
