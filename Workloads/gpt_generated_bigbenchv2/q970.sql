WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
sales_combined AS (
    SELECT
        COALESCE(s.item_id, w.item_id) AS item_id,
        COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w ON s.item_id = w.item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    sc.total_quantity,
    sc.total_revenue,
    AVG(pr.pr_sentiment) AS avg_sentiment
FROM sales_combined sc
JOIN items i ON sc.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY
    i.i_item_id,
    i.i_name,
    i.i_category,
    sc.total_quantity,
    sc.total_revenue
ORDER BY sc.total_revenue DESC
LIMIT 10
