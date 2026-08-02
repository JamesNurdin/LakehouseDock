WITH cs_agg AS (
  SELECT
    cs.cs_warehouse_sk,
    cs.cs_call_center_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  WHERE cs.cs_net_paid > 0
    AND cs.cs_quantity >= 1
    AND cs.cs_sold_date_sk BETWEEN 2450808 AND 2451079
    AND cs.cs_wholesale_cost > 0
  GROUP BY
    cs.cs_warehouse_sk,
    cs.cs_call_center_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_promo_sk
),
cust_intersect AS (
  SELECT cs_bill_customer_sk AS cust_sk
  FROM catalog_sales
  WHERE cs_net_paid > 100
  INTERSECT
  SELECT wr_refunded_customer_sk AS cust_sk
  FROM web_returns
  WHERE wr_return_amt > 50
)
SELECT
  w.w_city,
  cc.cc_division,
  cc.cc_tax_percentage,
  t.t_shift,
  p.p_discount_active,
  i.inv_quantity_on_hand,
  cp.cp_department,
  sm.sm_type,
  hd.hd_buy_potential,
  SUM(cs.total_sales) AS sum_sales,
  SUM(cs.sales_cnt) AS sum_sales_cnt,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS sum_store_return_amt,
  SUM(COALESCE(wr.wr_return_amt, 0)) AS sum_web_return_amt,
  ROW_NUMBER() OVER (ORDER BY SUM(cs.total_sales) DESC) AS rn
FROM cs_agg cs
JOIN cust_intersect ci ON cs.cs_bill_customer_sk = ci.cust_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
LEFT JOIN store_returns sr
  ON sr.sr_return_time_sk = t.t_time_sk
  AND sr.sr_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_time_sk = t.t_time_sk
  AND wr.wr_refunded_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_tax_percentage = 0.11
  AND cc.cc_division = 5
  AND t.t_shift = 'first'
  AND w.w_city = 'Riverside'
  AND p.p_discount_active = 'Y'
  AND i.inv_quantity_on_hand > 0
  AND (r_sr.r_reason_desc = 'Damaged' OR r_wr.r_reason_desc = 'Damaged')
GROUP BY
  w.w_city,
  cc.cc_division,
  cc.cc_tax_percentage,
  t.t_shift,
  p.p_discount_active,
  i.inv_quantity_on_hand,
  cp.cp_department,
  sm.sm_type,
  hd.hd_buy_potential
ORDER BY sum_sales DESC
LIMIT 100
