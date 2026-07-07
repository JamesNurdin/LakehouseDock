WITH store_sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_category,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category, i.i_item_id
),
web_sales_agg AS (
    SELECT
        'Online' AS s_store_name,
        i.i_category,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
),
combined_sales AS (
    SELECT
        s_store_name,
        i_category,
        i_item_id,
        total_quantity,
        total_revenue
    FROM store_sales_agg
    UNION ALL
    SELECT
        s_store_name,
        i_category,
        i_item_id,
        total_quantity,
        total_revenue
    FROM web_sales_agg
),
item_sentiment AS (
    SELECT
        i.i_item_id,
        AVG(CAST(pr.pr_sentiment AS double)) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    cs.s_store_name,
    cs.i_category,
    cs.i_item_id,
    cs.total_quantity,
    cs.total_revenue,
    COALESCE(isent.avg_sentiment, NULL) AS avg_sentiment,
    COALESCE(isent.review_count, 0) AS review_count
FROM combined_sales cs
LEFT JOIN item_sentiment isent ON cs.i_item_id = isent.i_item_id
ORDER BY cs.total_revenue DESC
LIMIT 100
