WITH sales AS (
   SELECT
      cs.cs_sold_date_sk,
      cs.cs_call_center_sk,
      cs.cs_net_profit,
      cs.cs_order_number,
      cs.cs_item_sk
   FROM catalog_sales cs
),
returns AS (
   SELECT
      cr.cr_returned_date_sk,
      cr.cr_call_center_sk,
      cr.cr_net_loss,
      cr.cr_order_number,
      cr.cr_item_sk
   FROM catalog_returns cr
)
SELECT
   d.d_year,
   d.d_moy AS month,
   cc.cc_name,
   SUM(s.cs_net_profit) AS total_sales_profit,
   COALESCE(SUM(r.cr_net_loss), 0) AS total_return_loss,
   SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit,
   COUNT(DISTINCT s.cs_order_number) AS distinct_orders
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns r
   ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
GROUP BY d.d_year, d.d_moy, cc.cc_name
ORDER BY d.d_year, month, net_profit DESC
