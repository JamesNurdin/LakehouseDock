WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue
    FROM items i
    LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.ss_item_id
    LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.ws_item_id
),
item_reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    isales.i_category,
    isales.i_category_id,
    SUM(isales.total_quantity) AS category_total_quantity,
    SUM(isales.total_revenue) AS category_total_revenue,
    AVG(ir.avg_sentiment) AS category_avg_sentiment,
    SUM(ir.review_count) AS category_review_count
FROM item_sales isales
LEFT JOIN item_reviews_agg ir ON isales.i_item_id = ir.pr_item_id
GROUP BY isales.i_category, isales.i_category_id
ORDER BY category_total_revenue DESC
LIMIT 10
