WITH sales_agg AS (
    -- Aggregate store sales per store and category
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category

    UNION ALL

    -- Aggregate web sales (online) per category; store_id is NULL for online
    SELECT
        CAST(NULL AS BIGINT) AS store_id,
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sales_by_store_category AS (
    SELECT
        store_id,
        i_category_id,
        i_category,
        SUM(total_quantity) AS total_quantity
    FROM sales_agg
    GROUP BY store_id, i_category_id, i_category
),
sentiment_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    sbc.i_category,
    sbc.total_quantity,
    sc.avg_sentiment,
    sc.review_count
FROM sales_by_store_category sbc
LEFT JOIN stores s ON s.s_store_id = sbc.store_id
JOIN sentiment_by_category sc
    ON sc.i_category_id = sbc.i_category_id
   AND sc.i_category = sbc.i_category
ORDER BY sbc.total_quantity DESC
LIMIT 100
