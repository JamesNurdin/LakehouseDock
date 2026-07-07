WITH item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           i.i_price,
           COALESCE(ss_agg.ss_qty, 0) + COALESCE(ws_agg.ws_qty, 0) AS total_qty
    FROM items i
    LEFT JOIN (
        SELECT ss.ss_item_id, SUM(ss.ss_quantity) AS ss_qty
        FROM store_sales ss
        GROUP BY ss.ss_item_id
    ) ss_agg ON i.i_item_id = ss_agg.ss_item_id
    LEFT JOIN (
        SELECT ws.ws_item_id, SUM(ws.ws_quantity) AS ws_qty
        FROM web_sales ws
        GROUP BY ws.ws_item_id
    ) ws_agg ON i.i_item_id = ws_agg.ws_item_id
),
item_reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    isales.i_category,
    isales.i_category_id,
    SUM(isales.total_qty) AS total_quantity_sold,
    AVG(COALESCE(irev.avg_sentiment, 0)) AS avg_review_sentiment,
    AVG(isales.i_price) AS avg_item_price
FROM item_sales isales
LEFT JOIN item_reviews irev ON isales.i_item_id = irev.i_item_id
GROUP BY isales.i_category, isales.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
