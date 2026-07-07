/*
  Goal: Calculate total quantity sold and average review sentiment per item category across store and web sales.
*/
WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
),
item_sentiment AS (
    SELECT i.i_item_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category
)
SELECT isales.i_category,
       SUM(isales.total_quantity) AS total_quantity_sold,
       AVG(isent.avg_sentiment) AS avg_review_sentiment
FROM item_sales isales
JOIN item_sentiment isent
  ON isales.i_item_id = isent.i_item_id
GROUP BY isales.i_category
ORDER BY total_quantity_sold DESC
