SELECT
  cc.cc_division_name,
  p.p_promo_name,
  hd_bill.hd_buy_potential,
  COUNT(DISTINCT cs.cs_order_number) AS total_orders,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
  CASE WHEN COUNT(DISTINCT cs.cs_order_number) = 0 THEN 0
       ELSE SUM(CASE WHEN cr.cr_return_amount IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT cs.cs_order_number)
  END AS return_rate_percent,
  AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
  SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
  AVG(hd_bill.hd_income_band_sk) AS avg_income_band,
  AVG(hd_return.hd_income_band_sk) AS avg_refund_income_band
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN household_demographics hd_return ON cr.cr_refunded_hdemo_sk = hd_return.hd_demo_sk
WHERE cc.cc_tax_percentage > 0.05
  AND p.p_start_date_sk >= 2450000
  AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
  AND hd_bill.hd_buy_potential = 'HIGH'
GROUP BY cc.cc_division_name, p.p_promo_name, hd_bill.hd_buy_potential
HAVING SUM(cs.cs_net_paid) > 1000000
ORDER BY total_net_profit DESC
LIMIT 100
