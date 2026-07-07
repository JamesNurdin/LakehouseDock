WITH item_sales AS (
    SELECT item_id, SUM(quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
    ) AS combined
    GROUP BY item_id
),
item_sentiment AS (
    SELECT i.i_item_id AS item_id,
           i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    isent.category,
    SUM(isent.avg_sentiment * isales.total_quantity) / SUM(isales.total_quantity) AS weighted_avg_sentiment,
    SUM(isales.total_quantity) AS total_quantity_sold
FROM item_sales isales
JOIN item_sentiment isent ON isales.item_id = isent.item_id
GROUP BY isent.category
ORDER BY weighted_avg_sentiment DESC
LIMIT 10
