SELECT
  i.i_item_id,
  i.i_product_name,
  s.s_store_name,
  sm.sm_type,
  r.r_reason_desc,
  w.web_name,
  SUM(ws.ws_net_profit) AS total_net_profit,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(cr.cr_net_loss) AS total_catalog_return_loss,
  COUNT(DISTINCT ws.ws_order_number) AS order_count,
  AVG(CASE WHEN ws.ws_ext_discount_amt > 0 THEN ws.ws_ext_discount_amt ELSE NULL END) AS avg_discount,
  CASE
    WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High'
    WHEN SUM(ws.ws_net_profit) BETWEEN 1000 AND 10000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category
FROM
  item i
  LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
  LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
  LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
  LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
  LEFT JOIN web_site w ON w.web_site_sk = ws.ws_web_site_sk
  LEFT JOIN customer_address ca ON ca.ca_address_sk = ws.ws_bill_addr_sk
WHERE
  i.i_current_price > 100
  AND s.s_market_id = 5
  AND ca.ca_state = 'CA'
  AND ws.ws_quantity >= 2
GROUP BY
  i.i_item_id,
  i.i_product_name,
  s.s_store_name,
  sm.sm_type,
  r.r_reason_desc,
  w.web_name
ORDER BY
  total_net_profit DESC
LIMIT 100
