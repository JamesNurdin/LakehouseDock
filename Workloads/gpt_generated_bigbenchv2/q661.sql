WITH sales_by_store_category AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
),
web_sales_by_category AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_sentiment_by_category AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.s_store_name,
    sbc.category_name,
    sbc.store_quantity,
    COALESCE(wc.web_quantity, 0) AS web_quantity,
    rs.avg_sentiment,
    rs.review_count
FROM sales_by_store_category sbc
JOIN stores s ON sbc.store_id = s.s_store_id
LEFT JOIN web_sales_by_category wc ON sbc.category_id = wc.category_id
LEFT JOIN review_sentiment_by_category rs ON sbc.category_id = rs.category_id
ORDER BY sbc.store_quantity DESC
LIMIT 100
