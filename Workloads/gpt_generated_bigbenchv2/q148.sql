WITH item_metrics AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        COALESCE(ss.store_quantity, 0) AS store_quantity,
        COALESCE(ws.web_quantity, 0) AS web_quantity,
        COALESCE(ra.sentiment_sum, 0) AS sentiment_sum,
        COALESCE(ra.review_count, 0) AS review_count
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id, SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ) ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN (
        SELECT ws_item_id, SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ) ws ON ws.ws_item_id = i.i_item_id
    LEFT JOIN (
        SELECT pr_item_id, SUM(pr_sentiment) AS sentiment_sum, COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ) ra ON ra.pr_item_id = i.i_item_id
)
SELECT
    im.i_category_id,
    im.i_category,
    SUM(im.store_quantity) AS total_store_quantity,
    SUM(im.web_quantity) AS total_web_quantity,
    SUM(im.store_quantity + im.web_quantity) AS total_quantity,
    CASE WHEN SUM(im.review_count) > 0 THEN SUM(im.sentiment_sum) / SUM(im.review_count) ELSE NULL END AS avg_sentiment,
    SUM(im.review_count) AS total_review_count
FROM item_metrics im
GROUP BY im.i_category_id, im.i_category
ORDER BY total_quantity DESC
LIMIT 10
