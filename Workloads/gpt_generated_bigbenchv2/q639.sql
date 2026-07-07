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
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
    COALESCE(ssa.store_revenue, 0) + COALESCE(wsa.web_revenue, 0) AS total_revenue,
    r.avg_sentiment,
    r.review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
