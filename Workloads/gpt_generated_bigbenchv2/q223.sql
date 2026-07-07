WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON i.i_item_id = ss.ss_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_category_sales AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON i.i_item_id = ws.ws_item_id
    GROUP BY i.i_category
),
review_category_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    si.i_category,
    si.store_quantity,
    wc.web_quantity,
    rc.avg_sentiment,
    rc.review_count
FROM store_item_sales si
JOIN stores s ON s.s_store_id = si.ss_store_id
LEFT JOIN web_category_sales wc ON wc.i_category = si.i_category
LEFT JOIN review_category_agg rc ON rc.i_category = si.i_category
ORDER BY si.store_quantity DESC
LIMIT 10
