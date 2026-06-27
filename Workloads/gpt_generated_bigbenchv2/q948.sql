WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_stats AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(store_sales_agg.store_revenue, 0) AS store_revenue,
    COALESCE(web_sales_agg.web_revenue, 0) AS web_revenue,
    COALESCE(store_sales_agg.store_revenue, 0) + COALESCE(web_sales_agg.web_revenue, 0) AS total_revenue,
    COALESCE(store_sales_agg.store_quantity, 0) AS store_quantity,
    COALESCE(web_sales_agg.web_quantity, 0) AS web_quantity,
    COALESCE(store_sales_agg.store_quantity, 0) + COALESCE(web_sales_agg.web_quantity, 0) AS total_quantity,
    review_stats.avg_rating,
    review_stats.review_count
FROM items i
LEFT JOIN store_sales_agg ON i.i_item_id = store_sales_agg.i_item_id
LEFT JOIN web_sales_agg ON i.i_item_id = web_sales_agg.i_item_id
LEFT JOIN review_stats ON i.i_item_id = review_stats.pr_item_id
ORDER BY total_revenue DESC
LIMIT 10
