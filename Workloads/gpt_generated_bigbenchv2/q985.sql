WITH web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
product_reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_name AS item_name,
    SUM(ss.ss_quantity) AS store_quantity,
    COALESCE(SUM(ws_agg.web_quantity), 0) AS web_quantity,
    SUM(ss.ss_quantity) + COALESCE(SUM(ws_agg.web_quantity), 0) AS total_quantity,
    pr_agg.avg_rating,
    pr_agg.review_count
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg ON i.i_item_id = ws_agg.ws_item_id
LEFT JOIN product_reviews_agg pr_agg ON i.i_item_id = pr_agg.pr_item_id
GROUP BY s.s_store_name, i.i_name, pr_agg.avg_rating, pr_agg.review_count
ORDER BY total_quantity DESC
LIMIT 20
