SELECT
  cc.cc_name,
  cp.cp_department,
  r.r_reason_desc,
  d_year_sold.d_year AS sold_year,
  SUM(s.cs_net_profit) AS total_profit,
  COUNT(DISTINCT s.cs_order_number) AS orders,
  AVG(s.cs_net_paid) AS avg_paid
FROM catalog_sales s
JOIN catalog_returns r_ret
  ON r_ret.cr_order_number = s.cs_order_number
JOIN call_center cc
  ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON r_ret.cr_reason_sk = r.r_reason_sk
JOIN customer cust_bill
  ON s.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_address addr_bill
  ON s.cs_bill_addr_sk = addr_bill.ca_address_sk
JOIN customer cust_ship
  ON s.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_address addr_ship
  ON s.cs_ship_addr_sk = addr_ship.ca_address_sk
JOIN date_dim d_year_sold
  ON s.cs_sold_date_sk = d_year_sold.d_date_sk
JOIN date_dim d_year_ship
  ON s.cs_ship_date_sk = d_year_ship.d_date_sk
JOIN date_dim d_returned
  ON r_ret.cr_returned_date_sk = d_returned.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = cust_bill.c_customer_sk
JOIN date_dim d_wp_create
  ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE s.cs_net_paid > (
    SELECT AVG(cs_net_paid)
    FROM catalog_sales
    WHERE cs_sold_date_sk = s.cs_sold_date_sk
  )
  AND r.r_reason_desc = 'Customer not satisfied'
GROUP BY GROUPING SETS (
  (cc.cc_name, cp.cp_department, r.r_reason_desc, d_year_sold.d_year),
  (cc.cc_name, cp.cp_department, r.r_reason_desc),
  (cc.cc_name, cp.cp_department),
  (cc.cc_name),
  ()
)
ORDER BY total_profit DESC
LIMIT 100
