WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
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
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS i_category_id,
    COALESCE(s.i_category, w.i_category, r.i_category) AS i_category,
    COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
    COALESCE(s.total_store_revenue, 0) + COALESCE(w.total_web_revenue, 0) AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_sentiment
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.i_category_id = w.i_category_id
FULL OUTER JOIN review_agg r ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
