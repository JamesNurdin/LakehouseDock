WITH aggregated AS (
 SELECT
   d.d_year,
   i.i_category,
   cc.cc_division_name,
   p.p_channel_tv,
   SUM(cs.cs_net_paid) AS total_net_paid,
   SUM(cs.cs_net_profit) AS total_net_profit,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
   SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2002
 GROUP BY d.d_year, i.i_category, cc.cc_division_name, p.p_channel_tv
)
SELECT
  a.*,
  a.total_net_paid / SUM(a.total_net_paid) OVER (PARTITION BY a.d_year) AS pct_of_year
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 200
