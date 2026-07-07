WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category,
    COALESCE(ss.store_qty, 0) AS store_qty,
    COALESCE(ss.store_revenue, 0) AS store_revenue,
    COALESCE(ws.web_qty, 0) AS web_qty,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) AS total_qty,
    (COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue
FROM items i
LEFT JOIN store_sales_agg ss
    ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws
    ON i.i_item_id = ws.i_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
ORDER BY total_revenue DESC
LIMIT 20
