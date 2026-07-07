WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS s_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    ss_agg.i_category,
    ss_agg.store_quantity,
    COALESCE(ws_agg.web_quantity, 0) AS web_quantity,
    COALESCE(rv_agg.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(rv_agg.review_count, 0) AS review_count
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.s_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg ON ss_agg.i_category = ws_agg.i_category
LEFT JOIN review_agg rv_agg ON ss_agg.i_category = rv_agg.i_category
ORDER BY s.s_store_name, ss_agg.i_category
