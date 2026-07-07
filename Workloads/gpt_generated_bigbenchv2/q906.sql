WITH in_store_sales AS (
    SELECT
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_instore_quantity
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category
),
online_sales AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS total_online_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_sentiment AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    isales.s_store_name,
    isales.i_category,
    isales.total_instore_quantity,
    COALESCE(osales.total_online_quantity, 0) AS total_online_quantity,
    rs.avg_review_sentiment
FROM in_store_sales isales
LEFT JOIN online_sales osales ON isales.i_category = osales.i_category
LEFT JOIN review_sentiment rs ON isales.i_category = rs.i_category
ORDER BY isales.s_store_name, isales.i_category
