WITH sales_union AS (
  SELECT
    i.i_category_id AS category_id,
    i.i_category AS category_name,
    s.s_store_name AS channel,
    ss.ss_quantity AS quantity,
    ss.ss_quantity * i.i_price AS sales_amount
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  JOIN stores s ON ss.ss_store_id = s.s_store_id

  UNION ALL

  SELECT
    i.i_category_id AS category_id,
    i.i_category AS category_name,
    'Online' AS channel,
    ws.ws_quantity AS quantity,
    ws.ws_quantity * i.i_price AS sales_amount
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
  category_id,
  category_name,
  channel,
  SUM(quantity) AS total_quantity,
  SUM(sales_amount) AS total_sales_amount
FROM sales_union
GROUP BY category_id, category_name, channel
ORDER BY total_quantity DESC
LIMIT 20
