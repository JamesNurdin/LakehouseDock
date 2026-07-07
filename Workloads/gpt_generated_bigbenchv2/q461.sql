WITH item_sentiment AS (
    SELECT
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
store_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(i.i_price * ss.ss_quantity) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(i.i_price * ws.ws_quantity) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    COALESCE(ss.category, ws.category) AS category,
    COALESCE(ss.store_quantity, 0) AS store_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(ss.store_revenue, 0) AS store_revenue,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    isent.avg_sentiment
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.category = ws.category
LEFT JOIN item_sentiment isent ON COALESCE(ss.category, ws.category) = isent.category
ORDER BY total_revenue DESC
LIMIT 10
