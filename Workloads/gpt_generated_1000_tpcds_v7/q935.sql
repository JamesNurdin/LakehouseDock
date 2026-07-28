SELECT
  w.w_warehouse_name,
  w.w_state,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
                     AND ws.ws_order_number = wr.wr_order_number
WHERE w.w_state = 'CA'
  AND p.p_channel_tv = 'N'
  AND ws.ws_sold_date_sk BETWEEN 2450581 AND 2450585
GROUP BY w.w_warehouse_name, w.w_state

UNION ALL

SELECT
  w.w_warehouse_name,
  w.w_state,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
                     AND ws.ws_order_number = wr.wr_order_number
WHERE w.w_state = 'TX'
  AND p.p_channel_email = 'N'
  AND ws.ws_sold_date_sk BETWEEN 2450581 AND 2450585
GROUP BY w.w_warehouse_name, w.w_state
ORDER BY total_sales DESC
