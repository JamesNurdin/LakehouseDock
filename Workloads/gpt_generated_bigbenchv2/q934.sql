WITH store_sales_by_store_cat AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category,
        i.i_category_id,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category, i.i_category_id
),
web_sales_by_cat AS (
    SELECT
        i.i_category,
        i.i_category_id,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
review_by_cat AS (
    SELECT
        i.i_category,
        i.i_category_id,
        COUNT(pr.pr_review_id) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    sssc.s_store_name,
    sssc.i_category,
    sssc.total_store_quantity,
    COALESCE(wsc.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(rc.review_count, 0) AS review_count,
    rc.avg_sentiment
FROM store_sales_by_store_cat sssc
LEFT JOIN web_sales_by_cat wsc
    ON sssc.i_category = wsc.i_category
    AND sssc.i_category_id = wsc.i_category_id
LEFT JOIN review_by_cat rc
    ON sssc.i_category = rc.i_category
    AND sssc.i_category_id = rc.i_category_id
WHERE sssc.total_store_quantity > 0
ORDER BY sssc.s_store_name, sssc.i_category
LIMIT 100
