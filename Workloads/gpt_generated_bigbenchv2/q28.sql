WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM items i
    JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM items i
    JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
    COALESCE(s.i_category, w.i_category, r.i_category) AS category_name,
    COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_sentiment
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
    ON w.i_category_id = s.i_category_id
FULL OUTER JOIN reviews_agg r
    ON r.i_category_id = COALESCE(s.i_category_id, w.i_category_id)
ORDER BY category_id
