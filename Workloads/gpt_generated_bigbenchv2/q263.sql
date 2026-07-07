WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_qty,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) AS category_id,
    COALESCE(ss.i_category, ws.i_category, r.i_category) AS category_name,
    COALESCE(ss.total_store_qty, 0) AS total_store_quantity,
    COALESCE(ss.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(ws.total_web_qty, 0) AS total_web_quantity,
    COALESCE(ws.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(r.avg_sentiment, 0) AS avg_review_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
ORDER BY (COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0)) DESC
LIMIT 10
