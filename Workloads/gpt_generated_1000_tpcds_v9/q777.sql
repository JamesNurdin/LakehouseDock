WITH catalog_agg AS (
   SELECT
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_net_profit ELSE 0 END) AS sales_profit,
      SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) AS return_loss,
      SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_net_profit ELSE 0 END) -
      SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_net_loss ELSE 0 END) AS net_adjusted_profit
   FROM catalog_sales cs
   FULL OUTER JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
   LEFT JOIN item i
     ON i.i_item_sk = COALESCE(cs.cs_item_sk, cr.cr_item_sk)
   LEFT JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk AND p.p_channel_email = 'N'
   WHERE i.i_rec_start_date >= DATE '2000-01-01'
   GROUP BY i.i_item_id, i.i_product_name
   HAVING (
      SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_net_profit ELSE 0 END) -
      SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_net_loss ELSE 0 END)
   ) > (
      SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2
   )
),
web_agg AS (
   SELECT
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS sales_profit,
      SUM(CASE WHEN wr.wr_item_sk IS NOT NULL THEN wr.wr_net_loss ELSE 0 END) AS return_loss,
      SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) -
      SUM(CASE WHEN wr.wr_item_sk IS NOT NULL THEN wr.wr_net_loss ELSE 0 END) AS net_adjusted_profit
   FROM web_sales ws
   FULL OUTER JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
   LEFT JOIN item i
     ON i.i_item_sk = COALESCE(ws.ws_item_sk, wr.wr_item_sk)
   LEFT JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk AND p.p_channel_email = 'N'
   WHERE i.i_rec_start_date >= DATE '2000-01-01'
   GROUP BY i.i_item_id, i.i_product_name
   HAVING SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) > (
      SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2
   )
)
SELECT *
FROM (
   SELECT 'catalog' AS channel, item_id, product_name, net_adjusted_profit
   FROM catalog_agg
   UNION ALL
   SELECT 'web' AS channel, item_id, product_name, net_adjusted_profit
   FROM web_agg
) AS combined
ORDER BY net_adjusted_profit DESC
LIMIT 100
