SELECT
  cc.cc_division AS division,
  i.i_category AS category,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cs.cs_net_paid_inc_tax) AS total_sales,
  SUM(cs.cs_net_profit) AS total_profit,
  SUM(p.p_cost) AS total_promo_cost,
  SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns,
  (SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_return_amt_inc_tax, 0))) AS net_profit_after_returns
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim td_sales ON cs.cs_sold_time_sk = td_sales.t_time_sk
LEFT JOIN store_returns sr
  ON cs.cs_item_sk = sr.sr_item_sk
  AND cs.cs_sold_time_sk = sr.sr_return_time_sk
LEFT JOIN time_dim td_returns ON sr.sr_return_time_sk = td_returns.t_time_sk
WHERE p.p_discount_active = 'Y'
  AND cc.cc_division IN (1, 2, 3, 4, 5)
  AND td_sales.t_hour BETWEEN 9 AND 17
GROUP BY cc.cc_division, i.i_category
HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
