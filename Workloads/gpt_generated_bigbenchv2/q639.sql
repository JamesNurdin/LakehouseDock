WITH review_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_qty,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    i.i_price,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(ss.total_store_qty, 0) AS total_store_qty,
    COALESCE(ss.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(ws.total_web_qty, 0) AS total_web_qty,
    COALESCE(ws.total_web_revenue, 0) AS total_web_revenue,
    (COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0)) AS total_quantity,
    (COALESCE(ss.total_store_revenue, 0) + COALESCE(ws.total_web_revenue, 0)) AS total_revenue,
    CASE WHEN (COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0)) = 0 THEN 0
         ELSE (COALESCE(ws.total_web_qty, 0) * 1.0) / (COALESCE(ss.total_store_qty, 0) + COALESCE(ws.total_web_qty, 0))
    END AS web_sales_qty_ratio
FROM items i
LEFT JOIN review_agg r ON r.pr_item_id = i.i_item_id
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
WHERE i.i_price > 0
ORDER BY total_revenue DESC
LIMIT 100
