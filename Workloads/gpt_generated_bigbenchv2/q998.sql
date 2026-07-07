WITH store_sales_by_cat AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_by_cat AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_by_cat AS (
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
    COALESCE(ssc.i_category, wsc.i_category, rc.i_category) AS category,
    COALESCE(ssc.total_store_qty, 0) AS total_store_quantity,
    COALESCE(wsc.total_web_qty, 0) AS total_web_quantity,
    COALESCE(rc.avg_sentiment, 0) AS average_review_sentiment,
    COALESCE(rc.review_count, 0) AS review_count
FROM store_sales_by_cat ssc
FULL OUTER JOIN web_sales_by_cat wsc
    ON ssc.i_category_id = wsc.i_category_id
    AND ssc.i_category = wsc.i_category
FULL OUTER JOIN reviews_by_cat rc
    ON COALESCE(ssc.i_category_id, wsc.i_category_id) = rc.i_category_id
    AND COALESCE(ssc.i_category, wsc.i_category) = rc.i_category
ORDER BY (COALESCE(ssc.total_store_qty, 0) + COALESCE(wsc.total_web_qty, 0)) DESC
LIMIT 10
