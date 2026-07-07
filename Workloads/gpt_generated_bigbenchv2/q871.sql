WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
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
    ws_agg.web_quantity,
    ss_agg.store_quantity + COALESCE(ws_agg.web_quantity, 0) AS total_quantity,
    ss_agg.store_revenue + COALESCE(ws_agg.web_revenue, 0) AS total_revenue,
    rev_agg.avg_sentiment,
    rev_agg.review_count
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg ON ss_agg.i_category = ws_agg.i_category
LEFT JOIN review_agg rev_agg ON ss_agg.i_category = rev_agg.i_category
ORDER BY total_revenue DESC
LIMIT 10
