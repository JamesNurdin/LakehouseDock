WITH item_sales AS (
    SELECT
        i.i_item_id,
        SUM(s.quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity FROM web_sales
    ) s
    JOIN items i ON i.i_item_id = s.item_id
    GROUP BY i.i_item_id
),
item_reviews AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(COALESCE(isales.total_quantity, 0)) AS total_quantity_sold,
    AVG(irev.avg_sentiment) AS avg_sentiment,
    AVG(i.i_price) AS avg_price
FROM items i
LEFT JOIN item_sales isales ON isales.i_item_id = i.i_item_id
LEFT JOIN item_reviews irev ON irev.i_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 20
