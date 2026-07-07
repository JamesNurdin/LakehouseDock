WITH sales_union AS (
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
SELECT i.i_category AS category,
       SUM(su.quantity) AS total_quantity_sold,
       COUNT(DISTINCT su.channel) AS channels_sold_in,
       AVG(CAST(pr.pr_sentiment AS double)) AS avg_sentiment
FROM sales_union su
JOIN items i ON su.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
