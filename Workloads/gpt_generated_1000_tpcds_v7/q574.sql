SELECT
    d.d_year,
    cc.cc_name,
    w.w_warehouse_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(ss.ss_ticket_number) AS store_sales_cnt,
    AVG(cs.cs_quantity) AS avg_quantity,
    MAX(cs.cs_sales_price) AS max_sales_price,
    MIN(cs.cs_sales_price) AS min_sales_price
FROM tpcds.date_dim d
JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_call_center_sk = cc.cc_call_center_sk
  AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_returned_time_sk = t.t_time_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
  AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  AND wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 1998
    AND cs.cs_quantity > 5
    AND cc.cc_state = 'CA'
    AND ca.ca_country = 'United States'
    AND ib.ib_upper_bound <= 50000
GROUP BY
    d.d_year,
    cc.cc_name,
    w.w_warehouse_name
ORDER BY
    total_net_paid DESC
LIMIT 100
