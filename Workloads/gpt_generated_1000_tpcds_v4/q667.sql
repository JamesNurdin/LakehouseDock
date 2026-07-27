SELECT
  d_sales.d_year,
  i_sales.i_brand,
  cc.cc_name,
  w_cr.w_warehouse_name,
  SUM(ss.ss_net_profit) AS total_sales_profit,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(cr.cr_net_loss) AS total_catalog_return_loss,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  COUNT(DISTINCT c_sales.c_customer_sk) AS distinct_customers_sales,
  COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i_sales
  ON ss.ss_item_sk = i_sales.i_item_sk
JOIN customer c_sales
  ON ss.ss_customer_sk = c_sales.c_customer_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN item i_return
  ON sr.sr_item_sk = i_return.i_item_sk
JOIN customer c_return
  ON sr.sr_customer_sk = c_return.c_customer_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN item i_cr
  ON cr.cr_item_sk = i_cr.i_item_sk
JOIN customer c_cr_refunded
  ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
JOIN call_center cc2
  ON cr.cr_call_center_sk = cc2.cc_call_center_sk
JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_sales.d_date_sk
JOIN item i_inv
  ON inv.inv_item_sk = i_inv.i_item_sk
JOIN warehouse w_inv
  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN customer c_wp
  ON wp.wp_customer_sk = c_wp.c_customer_sk
GROUP BY
  d_sales.d_year,
  i_sales.i_brand,
  cc.cc_name,
  w_cr.w_warehouse_name
ORDER BY total_sales_profit DESC
LIMIT 100
