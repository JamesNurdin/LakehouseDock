SELECT
    d.d_year AS sales_year,
    s.s_state,
    cp.cp_catalog_page_number,
    we.web_name,
    ib.ib_income_band_sk,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(cc.cc_gmt_offset) AS avg_call_center_offset
FROM tpcds.date_dim d
JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d.d_date_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.date_dim d2
  ON wp.wp_creation_date_sk = d2.d_date_sk
GROUP BY
    d.d_year,
    s.s_state,
    cp.cp_catalog_page_number,
    we.web_name,
    ib.ib_income_band_sk
ORDER BY total_store_sales DESC
