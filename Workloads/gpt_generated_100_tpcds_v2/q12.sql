SELECT i.i_brand,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category_id = 8
  AND i.i_current_price > 1.00
  AND i.i_rec_start_date <= DATE '2000-01-01'
  AND i.i_rec_end_date >= DATE '2000-01-01'
  AND ws.ws_net_profit > 0
GROUP BY i.i_brand
ORDER BY total_net_profit DESC
LIMIT 10
