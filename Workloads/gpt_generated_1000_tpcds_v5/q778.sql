SELECT
    cc.cc_name,
    d_sold.d_year,
    t_sold.t_meal_time,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(cs.cs_net_paid) AS avg_net_paid
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN web_returns wr
  ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
  ON wr.wr_returned_time_sk = t_ret.t_time_sk
WHERE d_sold.d_fy_year = 1908
  AND t_sold.t_meal_time = 'breakfast'
  AND cc.cc_state = 'CA'
  AND c_bill.c_birth_month = 6
GROUP BY cc.cc_name, d_sold.d_year, t_sold.t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
