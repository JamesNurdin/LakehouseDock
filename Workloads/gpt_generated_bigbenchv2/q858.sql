WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        i.i_price,
        COALESCE(sa.store_quantity, 0) AS store_quantity,
        COALESCE(wa.web_quantity, 0) AS web_quantity,
        ra.avg_sentiment,
        ra.review_count
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id, SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ) sa ON sa.ss_item_id = i.i_item_id
    LEFT JOIN (
        SELECT ws_item_id, SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ) wa ON wa.ws_item_id = i.i_item_id
    LEFT JOIN (
        SELECT pr_item_id, AVG(pr_sentiment) AS avg_sentiment, COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ) ra ON ra.pr_item_id = i.i_item_id
)
SELECT
    isales.i_category_id,
    isales.i_category,
    SUM(isales.store_quantity) AS total_store_quantity,
    SUM(isales.web_quantity) AS total_web_quantity,
    SUM(isales.store_quantity) + SUM(isales.web_quantity) AS total_quantity,
    AVG(isales.i_price) AS avg_price,
    AVG(isales.avg_sentiment) AS avg_sentiment,
    SUM(isales.review_count) AS total_reviews
FROM item_sales isales
GROUP BY
    isales.i_category_id,
    isales.i_category
ORDER BY total_quantity DESC
LIMIT 10
