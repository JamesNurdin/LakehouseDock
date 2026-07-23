SELECT
  cc_sale.cc_name AS call_center_name,
  d_sold.d_year AS sale_year,
  d_sold.d_month_seq AS sale_month_seq,
  sm_sale.sm_type AS ship_mode_type,
  COUNT(DISTINCT cs.cs_order_number) AS order_count,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales_amount,
  SUM(cs.cs_net_profit) AS total_sales_profit,
  SUM(cr.cr_net_loss) AS total_return_loss,
  CASE
    WHEN SUM(cs.cs_net_profit) >= SUM(cr.cr_net_loss) THEN 'Net Profit'
    ELSE 'Net Loss'
  END AS profit_category,
  (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit_all
FROM
  catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  JOIN call_center cc_sale ON cs.cs_call_center_sk = cc_sale.cc_call_center_sk
  JOIN catalog_page cp_sale ON cs.cs_catalog_page_sk = cp_sale.cp_catalog_page_sk
  JOIN ship_mode sm_sale ON cs.cs_ship_mode_sk = sm_sale.sm_ship_mode_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN catalog_page cp_return ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
  JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
  JOIN call_center cc_return ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
  JOIN ship_mode sm_return ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
  JOIN customer cust_refunded ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
  JOIN customer cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
WHERE
  d_sold.d_year = 2001
GROUP BY
  cc_sale.cc_name,
  d_sold.d_year,
  d_sold.d_month_seq,
  sm_sale.sm_type
ORDER BY
  total_sales_amount DESC
LIMIT 100
