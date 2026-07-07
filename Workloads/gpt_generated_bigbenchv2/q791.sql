SELECT
  i.i_category,
  CAST(i.i_price / 10 AS integer) * 10 AS price_range,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(ws.ws_quantity * i.i_price) AS total_revenue,
  AVG(i.i_price) AS avg_price
FROM web_sales ws
JOIN items i
  ON ws.ws_item_id = i.i_item_id
GROUP BY
  i.i_category,
  CAST(i.i_price / 10 AS integer) * 10
ORDER BY total_revenue DESC
LIMIT 20
