WITH store_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    COALESCE(s.i_category, w.i_category, r.i_category) AS category,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity_sold,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
    COALESCE(r.avg_sentiment, 0) AS avg_review_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category = w.i_category
FULL OUTER JOIN reviews_agg r ON COALESCE(s.i_category, w.i_category) = r.i_category
ORDER BY total_revenue DESC
LIMIT 10
