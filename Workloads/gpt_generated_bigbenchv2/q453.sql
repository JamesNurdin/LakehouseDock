WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_store_id) AS store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
    COALESCE(s.i_category, w.i_category, r.i_category) AS category,
    s.total_store_quantity,
    w.total_web_quantity,
    r.review_count,
    r.avg_review_sentiment
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category_id = w.i_category_id
FULL OUTER JOIN reviews_agg r ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
ORDER BY s.total_store_quantity DESC NULLS LAST
LIMIT 20
