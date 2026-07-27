SELECT
  sm.sm_ship_mode_id,
  p.p_promo_name,
  rs.r_reason_desc,
  SUM(ws.ws_net_profit)          AS total_net_profit,
  SUM(cr.cr_return_amount)      AS total_return_amount,
  COUNT(DISTINCT ws.ws_order_number) AS orders,
  COUNT(DISTINCT cr.cr_order_number) AS returns
FROM catalog_returns cr
JOIN ship_mode sm   ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk          -- join 1
JOIN reason rs      ON cr.cr_reason_sk   = rs.r_reason_sk                -- join 2
JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk           -- join 3
JOIN customer cust_ref  ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk   -- join 4
JOIN customer cust_ret  ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk   -- join 5
JOIN web_sales ws   ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk           -- join 6 (links the two fact tables via ship mode)
JOIN promotion p    ON ws.ws_promo_sk = p.p_promo_sk                     -- join 7
JOIN web_page wp    ON ws.ws_web_page_sk = wp.wp_web_page_sk           -- join 8
JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk -- join 9
JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk -- join 10
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk           -- join 11
JOIN customer wp_cust ON wp.wp_customer_sk = wp_cust.c_customer_sk   -- join 12
GROUP BY
  sm.sm_ship_mode_id,
  p.p_promo_name,
  rs.r_reason_desc
ORDER BY total_net_profit DESC
LIMIT 100
