WITH in_store_sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_instore_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_instore_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
online_sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_online_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_online_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_sentiment AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(isales.i_category_id, osales.i_category_id, rs.i_category_id) AS category_id,
    COALESCE(isales.i_category, osales.i_category, rs.i_category) AS category_name,
    COALESCE(isales.total_instore_quantity, 0) AS total_instore_quantity,
    COALESCE(isales.total_instore_revenue, 0) AS total_instore_revenue,
    COALESCE(osales.total_online_quantity, 0) AS total_online_quantity,
    COALESCE(osales.total_online_revenue, 0) AS total_online_revenue,
    rs.avg_sentiment
FROM in_store_sales isales
FULL OUTER JOIN online_sales osales
    ON isales.i_category_id = osales.i_category_id
FULL OUTER JOIN review_sentiment rs
    ON COALESCE(isales.i_category_id, osales.i_category_id) = rs.i_category_id
ORDER BY total_instore_revenue DESC
LIMIT 10
