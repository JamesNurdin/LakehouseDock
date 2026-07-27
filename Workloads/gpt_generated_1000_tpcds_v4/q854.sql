SELECT
    cc.cc_name,
    sm.sm_type,
    r_cr.r_reason_desc,
    td_sold.t_hour,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_sold
  ON cs.cs_sold_time_sk = td_sold.t_time_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN ship_mode sm_ret
  ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN time_dim td_ret
  ON cr.cr_returned_time_sk = td_ret.t_time_sk
LEFT JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
LEFT JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
LEFT JOIN store_returns sr
  ON sr.sr_reason_sk = r_cr.r_reason_sk
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN time_dim td_sr
  ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN customer_address ca_store_ret
  ON sr.sr_addr_sk = ca_store_ret.ca_address_sk
GROUP BY
    cc.cc_name,
    sm.sm_type,
    r_cr.r_reason_desc,
    td_sold.t_hour
ORDER BY total_sales DESC
LIMIT 100
