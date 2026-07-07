WITH store_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
sales AS (
    SELECT
        i.i_category,
        COALESCE(sa.store_qty, 0) AS store_qty,
        COALESCE(wa.web_qty, 0) AS web_qty,
        i.i_price
    FROM items i
    LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
    LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
),
sales_agg AS (
    SELECT
        i_category,
        SUM(store_qty) AS total_store_qty,
        SUM(web_qty) AS total_web_qty,
        SUM((store_qty + web_qty) * i_price) AS total_revenue
    FROM sales
    GROUP BY i_category
),
reviews AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.i_category,
    s.total_store_qty,
    s.total_web_qty,
    (s.total_store_qty + s.total_web_qty) AS total_quantity,
    s.total_revenue,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
JOIN reviews r ON s.i_category = r.i_category
ORDER BY s.total_revenue DESC
LIMIT 5
