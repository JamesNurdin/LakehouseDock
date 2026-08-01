WITH
  cr_agg AS (
    SELECT
      cr.cr_order_number,
      SUM(cr.cr_return_amount) AS total_cr_return_amount,
      SUM(cr.cr_net_loss) AS total_cr_net_loss
    FROM catalog_returns cr
      JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
      JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
      JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
      JOIN time_dim td2 ON cr.cr_returned_time_sk = td2.t_time_sk
    GROUP BY cr.cr_order_number
  ),
  wr_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS c_customer_sk,
      SUM(wr.wr_return_amt) AS total_wr_return_amt,
      SUM(wr.wr_net_loss) AS total_wr_net_loss
    FROM web_returns wr
      JOIN time_dim td3 ON wr.wr_returned_time_sk = td3.t_time_sk
    GROUP BY wr.wr_refunded_customer_sk
  )
SELECT
  cc.cc_name AS call_center_name,
  sm.sm_code AS ship_mode_code,
  p.p_promo_name AS promotion_name,
  td_sales.t_hour AS sale_hour,
  SUM(cs.cs_net_paid) AS total_sales,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  COALESCE(SUM(cr.total_cr_return_amount), 0) AS total_catalog_return_amount,
  COALESCE(SUM(cr.total_cr_net_loss), 0) AS total_catalog_return_loss,
  COALESCE(SUM(wr.total_wr_return_amt), 0) AS total_web_return_amount,
  COALESCE(SUM(wr.total_wr_net_loss), 0) AS total_web_return_loss,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim td_sales ON cs.cs_sold_time_sk = td_sales.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN cr_agg cr ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN wr_agg wr ON c.c_customer_sk = wr.c_customer_sk
WHERE cc.cc_state = 'CA'
  AND sm.sm_code = 'AIR'
  AND td_sales.t_hour BETWEEN 9 AND 17
GROUP BY cc.cc_name, sm.sm_code, p.p_promo_name, td_sales.t_hour
ORDER BY total_sales DESC
LIMIT 100
