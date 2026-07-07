WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        COALESCE(ss.total_quantity, 0) + COALESCE(ws.total_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id, SUM(ss_quantity) AS total_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ) ss ON i.i_item_id = ss.ss_item_id
    LEFT JOIN (
        SELECT ws_item_id, SUM(ws_quantity) AS total_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ) ws ON i.i_item_id = ws.ws_item_id
),
item_reviews AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    isales.i_category_id,
    isales.i_category,
    SUM(isales.total_quantity) AS total_quantity_sold,
    SUM(COALESCE(ireviews.review_count, 0)) AS total_review_count,
    AVG(ireviews.avg_sentiment) AS avg_sentiment_across_items
FROM item_sales isales
LEFT JOIN item_reviews ireviews ON isales.i_item_id = ireviews.pr_item_id
GROUP BY isales.i_category_id, isales.i_category
ORDER BY total_quantity_sold DESC
