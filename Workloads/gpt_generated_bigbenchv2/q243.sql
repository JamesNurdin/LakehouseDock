WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category, s.s_store_name
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
review_sentiment_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    ss.i_category_id,
    ss.i_category,
    ss.s_store_name,
    ss.total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    rs.avg_sentiment
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
    AND ss.i_category = ws.i_category
LEFT JOIN review_sentiment_agg rs
    ON ss.i_category_id = rs.i_category_id
    AND ss.i_category = rs.i_category
ORDER BY ss.total_store_quantity DESC
LIMIT 100
