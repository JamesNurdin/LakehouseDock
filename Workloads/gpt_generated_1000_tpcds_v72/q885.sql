SELECT
  d.d_year,
  s.s_state,
  i.i_brand,
  SUM(ss.ss_net_paid) AS total_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(cr.cr_return_amount) AS total_catalog_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM
  tpcds.date_dim d
  JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND w.w_country = 'United States'
GROUP BY
  d.d_year,
  s.s_state,
  i.i_brand
ORDER BY
  total_sales DESC
LIMIT 100
