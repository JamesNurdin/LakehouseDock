WITH sales_union AS (
 SELECT
   ss.ss_sold_date_sk AS date_sk,
   ss.ss_item_sk AS item_sk,
   ss.ss_quantity AS quantity,
   ss.ss_net_paid AS net_paid,
   ss.ss_net_profit AS net_profit,
   'store' AS channel,
   ss.ss_ticket_number AS order_number
 FROM store_sales ss
 UNION ALL
 SELECT
   cs.cs_sold_date_sk AS date_sk,
   cs.cs_item_sk AS item_sk,
   cs.cs_quantity AS quantity,
   cs.cs_net_paid AS net_paid,
   cs.cs_net_profit AS net_profit,
   'catalog' AS channel,
   cs.cs_order_number AS order_number
 FROM catalog_sales cs
 UNION ALL
 SELECT
   ws.ws_sold_date_sk AS date_sk,
   ws.ws_item_sk AS item_sk,
   ws.ws_quantity AS quantity,
   ws.ws_net_paid AS net_paid,
   ws.ws_net_profit AS net_profit,
   'web' AS channel,
   ws.ws_order_number AS order_number
 FROM web_sales ws
),
returns_union AS (
 SELECT
   sr.sr_returned_date_sk AS date_sk,
   sr.sr_item_sk AS item_sk,
   sr.sr_return_quantity AS quantity,
   sr.sr_return_amt AS return_amt,
   sr.sr_net_loss AS net_loss,
   'store' AS channel,
   sr.sr_ticket_number AS order_number
 FROM store_returns sr
 UNION ALL
 SELECT
   cr.cr_returned_date_sk AS date_sk,
   cr.cr_item_sk AS item_sk,
   cr.cr_return_quantity AS quantity,
   cr.cr_return_amount AS return_amt,
   cr.cr_net_loss AS net_loss,
   'catalog' AS channel,
   cr.cr_order_number AS order_number
 FROM catalog_returns cr
 UNION ALL
 SELECT
   wr.wr_returned_date_sk AS date_sk,
   wr.wr_item_sk AS item_sk,
   wr.wr_return_quantity AS quantity,
   wr.wr_return_amt AS return_amt,
   wr.wr_net_loss AS net_loss,
   'web' AS channel,
   wr.wr_order_number AS order_number
 FROM web_returns wr
)
SELECT
 d.d_year,
 i.i_category,
 s.channel,
 COUNT(DISTINCT s.order_number) AS orders,
 SUM(s.quantity) AS total_quantity_sold,
 SUM(s.net_paid) AS total_sales,
 SUM(s.net_profit) AS total_profit,
 SUM(COALESCE(r.quantity, 0)) AS total_quantity_returned,
 SUM(COALESCE(r.return_amt, 0)) AS total_return_amount,
 SUM(COALESCE(r.net_loss, 0)) AS total_return_loss,
 (SUM(COALESCE(r.return_amt, 0)) / NULLIF(SUM(s.net_paid), 0)) * 100 AS return_rate_percent,
 AVG(s.net_profit / NULLIF(s.quantity, 0)) AS avg_profit_per_item
FROM sales_union s
LEFT JOIN returns_union r
  ON s.channel = r.channel
  AND s.order_number = r.order_number
  AND s.item_sk = r.item_sk
JOIN date_dim d
  ON s.date_sk = d.d_date_sk
JOIN item i
  ON s.item_sk = i.i_item_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY d.d_year, i.i_category, s.channel
