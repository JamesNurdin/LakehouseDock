WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) AS category_id,
    COALESCE(ss.i_category, ws.i_category, r.i_category) AS category,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_sentiment
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN review_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
ORDER BY total_quantity DESC
LIMIT 20
