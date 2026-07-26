SELECT
  i.i_category,
  SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) AS total_catalog_net_loss,
  SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_net_loss ELSE 0 END) AS total_store_net_loss,
  SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS total_web_net_profit,
  CASE WHEN SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) = 0 THEN NULL
       ELSE (SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) +
             SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_net_loss ELSE 0 END)) /
            SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END)
  END AS loss_to_profit_ratio,
  DENSE_RANK() OVER (ORDER BY 
    CASE WHEN SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) = 0 THEN 0
         ELSE (SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) +
               SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_net_loss ELSE 0 END)) /
              SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END)
    END DESC) AS ratio_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
GROUP BY i.i_category
HAVING SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) IS NOT NULL
ORDER BY ratio_rank
LIMIT 10
