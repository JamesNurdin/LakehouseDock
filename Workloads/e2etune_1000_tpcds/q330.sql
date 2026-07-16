SELECT
  p.p_promo_name,
  i.i_category,
  cs.cs_ship_mode_sk AS ship_mode,
  cs.cs_sold_date_sk AS sold_date,
  SUM(cs.cs_net_profit) AS catalog_net_profit,
  SUM(ws.ws_net_profit) AS web_net_profit,
  SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
  COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
  (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_adj,
  COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
  AVG(i.i_current_price) AS avg_item_price,
  SUM(cs.cs_quantity) + SUM(ws.ws_quantity) AS total_quantity_sold,
  SUM(sr.sr_return_quantity) + SUM(wr.wr_return_quantity) AS total_quantity_returned,
  (SUM(cs.cs_quantity) + SUM(ws.ws_quantity) - (SUM(sr.sr_return_quantity) + SUM(wr.wr_return_quantity))) AS net_quantity_sold
FROM catalog_sales cs
LEFT JOIN web_sales ws
  ON cs.cs_item_sk = ws.ws_item_sk
  AND cs.cs_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN store_returns sr
  ON cs.cs_item_sk = sr.sr_item_sk
  AND cs.cs_bill_customer_sk = sr.sr_customer_sk
LEFT JOIN web_returns wr
  ON ws.ws_item_sk = wr.wr_item_sk
  AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450870 AND 2450900
  AND cs.cs_ext_discount_amt > 500
  AND p.p_discount_active = 'Y'
GROUP BY p.p_promo_name, i.i_category, cs.cs_ship_mode_sk, cs.cs_sold_date_sk
ORDER BY net_profit_adj DESC
LIMIT 10
