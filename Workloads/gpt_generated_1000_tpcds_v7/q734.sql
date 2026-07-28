SELECT
  d.d_date,
  cc.cc_name,
  cp.cp_type,
  i.i_category,
  sm.sm_type,
  hd.hd_buy_potential,
  ca.ca_state,
  wp.wp_type,
  SUM(cs.cs_ext_sales_price)          AS total_catalog_sales,
  SUM(cr.cr_return_amount)            AS total_catalog_returns,
  SUM(sr.sr_return_amt)               AS total_store_returns,
  SUM(ws.ws_ext_sales_price)          AS total_web_sales,
  SUM(wr.wr_return_amt)               AS total_web_returns,
  SUM(inv.inv_quantity_on_hand)       AS inventory_on_hand
FROM tpcds.date_dim d
JOIN tpcds.call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = i.i_item_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d.d_date_sk
JOIN tpcds.web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
 AND ws.ws_item_sk = i.i_item_sk
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = i.i_item_sk
JOIN tpcds.web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 1998
GROUP BY
  d.d_date,
  cc.cc_name,
  cp.cp_type,
  i.i_category,
  sm.sm_type,
  hd.hd_buy_potential,
  ca.ca_state,
  wp.wp_type
HAVING SUM(cs.cs_ext_sales_price) > 0
ORDER BY total_catalog_sales DESC
LIMIT 100
