WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_sentiment_agg AS (
    SELECT
        i.i_category,
        AVG(CAST(pr.pr_sentiment AS DOUBLE)) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    ss_agg.i_category,
    ss_agg.store_qty,
    COALESCE(ws_agg.web_qty, 0) AS web_qty,
    rs_agg.avg_sentiment,
    COALESCE(rs_agg.review_count, 0) AS review_count,
    (ss_agg.store_qty + COALESCE(ws_agg.web_qty, 0)) AS total_qty
FROM store_sales_agg ss_agg
JOIN stores s
    ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg
    ON ss_agg.i_category = ws_agg.i_category
LEFT JOIN review_sentiment_agg rs_agg
    ON ss_agg.i_category = rs_agg.i_category
ORDER BY total_qty DESC
LIMIT 100
