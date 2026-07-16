WITH sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_promo_sk AS promo_sk,
         cs.cs_order_number AS order_number,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_promo_sk,
         ss.ss_ticket_number,
         ss.ss_net_profit,
         'store'
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_promo_sk,
         ws.ws_order_number,
         ws.ws_net_profit,
         'web'
  FROM web_sales ws
),
returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_item_sk AS item_sk,
         cr.cr_order_number AS order_number,
         cr.cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_ticket_number,
         sr.sr_net_loss,
         'store'
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_item_sk,
         wr.wr_order_number,
         wr.wr_net_loss,
         'web'
  FROM web_returns wr
)
SELECT d.d_year,
       s.channel,
       i.i_category,
       i.i_brand,
       p.p_promo_name,
       sum(s.net_profit) AS total_profit,
       sum(coalesce(r.net_loss, 0)) AS total_loss,
       sum(s.net_profit) - sum(coalesce(r.net_loss, 0)) AS net_profit,
       count(distinct s.order_number) AS orders,
       count(distinct r.order_number) AS returns
FROM sales s
LEFT JOIN returns r
  ON s.order_number = r.order_number
  AND s.channel = r.channel
JOIN date_dim d
  ON s.date_sk = d.d_date_sk
LEFT JOIN item i
  ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON s.promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, s.channel, i.i_category, i.i_brand, p.p_promo_name
ORDER BY net_profit DESC
LIMIT 100
