WITH all_sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COUNT(DISTINCT pr.pr_review_id) AS review_count,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       SUM(s.quantity) AS total_quantity_sold,
       SUM(CASE WHEN s.channel = 'store' THEN s.quantity ELSE 0 END) AS store_quantity,
       SUM(CASE WHEN s.channel = 'web' THEN s.quantity ELSE 0 END) AS web_quantity
FROM items i
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
JOIN all_sales s ON s.item_id = i.i_item_id
GROUP BY i.i_item_id, i.i_name, i.i_category, i.i_price
ORDER BY total_quantity_sold DESC
LIMIT 100
