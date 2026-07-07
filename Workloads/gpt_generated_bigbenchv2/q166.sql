WITH store_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
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
    COALESCE(ss.category, ws.category, r.category) AS category,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) AS total_sales_amount,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.category = ws.category
FULL OUTER JOIN reviews_agg r ON COALESCE(ss.category, ws.category) = r.category
ORDER BY total_sales_amount DESC
LIMIT 10
