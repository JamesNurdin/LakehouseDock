WITH unified_sales AS (
 SELECT
   ss.ss_sold_date_sk AS sold_date_sk,
   ss.ss_sold_time_sk AS sold_time_sk,
   ss.ss_item_sk AS item_sk,
   ss.ss_quantity AS quantity,
   ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
   ss.ss_net_profit AS net_profit,
   'store' AS channel,
   ca.ca_state AS state,
   ss.ss_promo_sk AS promo_sk,
   ss.ss_ext_discount_amt AS discount_amt
 FROM store_sales ss
 JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk

 UNION ALL

 SELECT
   cs.cs_sold_date_sk,
   cs.cs_sold_time_sk,
   cs.cs_item_sk,
   cs.cs_quantity,
   cs.cs_net_paid_inc_tax,
   cs.cs_net_profit,
   'catalog',
   cc.cc_state,
   cs.cs_promo_sk,
   cs.cs_ext_discount_amt
 FROM catalog_sales cs
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

 UNION ALL

 SELECT
   ws.ws_sold_date_sk,
   ws.ws_sold_time_sk,
   ws.ws_item_sk,
   ws.ws_quantity,
   ws.ws_net_paid_inc_tax,
   ws.ws_net_profit,
   'web',
   ca2.ca_state,
   ws.ws_promo_sk,
   ws.ws_ext_discount_amt
 FROM web_sales ws
 JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
),
aggregated_sales AS (
 SELECT
   d.d_year AS year,
   us.channel,
   i.i_category AS category,
   us.state,
   SUM(us.quantity) AS total_quantity,
   SUM(us.net_paid_inc_tax) AS total_revenue,
   SUM(us.net_profit) AS total_profit,
   SUM(us.discount_amt) AS total_discount
 FROM unified_sales us
 JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
 JOIN item i ON us.item_sk = i.i_item_sk
 GROUP BY d.d_year, us.channel, i.i_category, us.state
 HAVING SUM(us.net_paid_inc_tax) > 0
)
SELECT
  year,
  channel,
  category,
  state,
  total_quantity,
  total_revenue,
  total_profit,
  total_discount,
  ROW_NUMBER() OVER (PARTITION BY year, channel ORDER BY total_revenue DESC) AS category_rank
FROM aggregated_sales
ORDER BY year, channel, total_revenue DESC
