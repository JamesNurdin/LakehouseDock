WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        COALESCE(ss.store_quantity, 0) AS store_quantity,
        COALESCE(ss.store_revenue, 0) AS store_revenue,
        COALESCE(ws.web_quantity, 0) AS web_quantity,
        COALESCE(ws.web_revenue, 0) AS web_revenue,
        COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
        COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue
    FROM items i
    LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
    LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
)
SELECT
    isales.i_name,
    isales.i_category_name,
    isales.total_quantity,
    isales.total_revenue,
    ir.avg_rating
FROM item_sales isales
LEFT JOIN item_ratings ir ON isales.i_item_id = ir.i_item_id
ORDER BY isales.total_revenue DESC
LIMIT 10
