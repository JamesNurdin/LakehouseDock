WITH store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS total_online_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_sentiment_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    ss.s_store_name,
    ss.i_category,
    ss.total_store_quantity,
    COALESCE(ws.total_online_quantity, 0) AS total_online_quantity,
    rs.avg_review_sentiment
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.i_category = ws.i_category
LEFT JOIN review_sentiment_agg rs ON ss.i_category = rs.i_category
ORDER BY ss.total_store_quantity DESC
