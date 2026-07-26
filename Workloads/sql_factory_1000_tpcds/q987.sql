SELECT
  i.i_category,
  SUM(ws.ws_net_profit) AS total_web_profit,
  AVG(cr.cr_net_loss) AS avg_catalog_loss,
  MAX(sr.sr_net_loss) AS max_store_loss,
  (SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss),0) - COALESCE(SUM(sr.sr_net_loss),0)) AS net_margin,
  DENSE_RANK() OVER (ORDER BY (SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss),0) - COALESCE(SUM(sr.sr_net_loss),0)) DESC) AS margin_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
GROUP BY i.i_category
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY margin_rank
LIMIT 15
