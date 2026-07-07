WITH combined_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    GROUP BY cs.item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    isales.total_quantity,
    AVG(pr.pr_sentiment) AS avg_sentiment
FROM item_sales isales
JOIN items i ON isales.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY
    i.i_item_id,
    i.i_name,
    i.i_category,
    i.i_price,
    isales.total_quantity
ORDER BY isales.total_quantity DESC
LIMIT 10
