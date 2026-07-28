SELECT
  cc.cc_call_center_id,
  i.i_category,
  c.c_birth_month,
  SUM(cs.cs_quantity) AS total_quantity_sold,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY SUM(cs.cs_net_paid) DESC) AS net_paid_rank
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE i.i_rec_end_date = DATE '2000-10-26'
  AND cc.cc_rec_start_date >= DATE '1998-01-01'
  AND cc.cc_rec_start_date < DATE '2002-01-01'
  AND wp.wp_image_count >= 3
  AND c.c_birth_month = 7
GROUP BY
  cc.cc_call_center_id,
  i.i_category,
  c.c_birth_month
ORDER BY total_net_paid DESC
LIMIT 100
