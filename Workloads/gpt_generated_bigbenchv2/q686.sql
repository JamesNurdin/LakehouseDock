WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    ss_agg.i_category,
    ss_agg.total_store_quantity,
    COALESCE(ws_agg.total_web_quantity, 0) AS total_web_quantity,
    rv_agg.avg_sentiment
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg ON ss_agg.i_category = ws_agg.i_category
LEFT JOIN reviews_agg rv_agg ON ss_agg.i_category = rv_agg.i_category
ORDER BY s.s_store_name, ss_agg.i_category
