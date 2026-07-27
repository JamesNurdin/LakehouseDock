SELECT
    cc.cc_name AS call_center_name,
    s.s_city AS store_city,
    r.r_reason_desc AS return_reason,
    d_sold.d_date AS sold_date,
    CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_wr
  ON cs.cs_sold_date_sk = d_wr.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r2
  ON wr.wr_reason_sk = r2.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr_exists
    WHERE wr_exists.wr_order_number = cs.cs_order_number
      AND wr_exists.wr_return_quantity > 0
)
GROUP BY
    cc.cc_name,
    s.s_city,
    r.r_reason_desc,
    d_sold.d_date,
    CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END
ORDER BY total_sales DESC
LIMIT 100
