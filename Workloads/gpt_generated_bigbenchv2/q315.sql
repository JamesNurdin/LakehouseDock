WITH combined_sales AS (
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
       SUM(cs.quantity) AS total_quantity,
       SUM(cs.quantity * i.i_price) AS total_revenue,
       SUM(CASE WHEN cs.channel = 'store' THEN cs.quantity ELSE 0 END) AS store_quantity,
       SUM(CASE WHEN cs.channel = 'web' THEN cs.quantity ELSE 0 END) AS web_quantity
FROM combined_sales cs
JOIN items i
  ON cs.item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
LIMIT 10
