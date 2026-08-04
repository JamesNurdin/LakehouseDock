( 
SELECT
  cc.cc_name,
  i.i_category,
  hd.hd_buy_potential,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_net_paid_inc_tax) AS total_sales,
  SUM(wr.wr_net_loss) AS total_return_loss,
  AVG(cs.cs_net_paid_inc_tax) AS avg_sales
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_category_id = 7
  AND i.i_formulation LIKE '%goldenrod%'
  AND cc.cc_class = 'large'
  AND hd.hd_buy_potential = '>10000'
  AND cs.cs_ship_hdemo_sk = 4052
  AND cs.cs_net_paid_inc_tax > 1000
GROUP BY cc.cc_name, i.i_category, hd.hd_buy_potential
HAVING COUNT(DISTINCT cs.cs_order_number) >= 1
) 
EXCEPT 
( 
SELECT
  cc.cc_name,
  i.i_category,
  hd.hd_buy_potential,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_net_paid_inc_tax) AS total_sales,
  SUM(wr.wr_net_loss) AS total_return_loss,
  AVG(cs.cs_net_paid_inc_tax) AS avg_sales
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_category_id = 7
  AND i.i_formulation LIKE '%goldenrod%'
  AND cc.cc_class = 'large'
  AND hd.hd_buy_potential = '>10000'
  AND cs.cs_ship_hdemo_sk = 4052
  AND cs.cs_net_paid_inc_tax > 2000
GROUP BY cc.cc_name, i.i_category, hd.hd_buy_potential
HAVING COUNT(DISTINCT cs.cs_order_number) >= 1
) 
LIMIT 100
