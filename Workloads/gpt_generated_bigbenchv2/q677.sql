WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
sales_agg AS (
    SELECT
        COALESCE(s.item_id, w.item_id) AS item_id,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w ON s.item_id = w.item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    SUM(sa.total_quantity) AS total_quantity_sold,
    SUM(sa.total_revenue) AS total_revenue,
    AVG(r.avg_sentiment) AS avg_item_sentiment,
    COUNT(r.item_id) AS items_with_reviews
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
LIMIT 10
