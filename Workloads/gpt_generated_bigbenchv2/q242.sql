WITH avg_sentiment AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    a.i_item_id,
    a.i_name,
    a.i_category,
    a.avg_sentiment,
    COALESCE(s.store_qty, 0) AS store_quantity,
    COALESCE(w.web_qty, 0) AS web_quantity,
    COALESCE(s.store_revenue, 0) AS store_revenue,
    COALESCE(w.web_revenue, 0) AS web_revenue,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
FROM avg_sentiment a
LEFT JOIN store_sales_agg s ON a.i_item_id = s.i_item_id
LEFT JOIN web_sales_agg w ON a.i_item_id = w.i_item_id
WHERE a.avg_sentiment >= 3
ORDER BY total_revenue DESC
LIMIT 10
