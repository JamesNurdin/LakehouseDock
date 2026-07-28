-- Goal: Aggregate sales and return metrics across store, catalog, and web channels by year, product category and store, using a deep join of all 19 TPC‑DS tables.
SELECT
    d_sold.d_year,
    i.i_category,
    s.s_store_name,
    SUM(ss.ss_net_paid)                              AS total_store_sales,
    SUM(COALESCE(sr.sr_net_loss, 0))                AS total_store_return_loss,
    SUM(cs.cs_net_paid)                              AS total_catalog_sales,
    SUM(COALESCE(cr.cr_net_loss, 0))                AS total_catalog_return_loss,
    SUM(ws.ws_net_paid)                              AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number)             AS unique_store_transactions
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk

-- Store returns (optional, left‑joined)
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim t_ret
  ON sr.sr_return_time_sk = t_ret.t_time_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk

-- Catalog sales and related dimensions
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs
  ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs
  ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk

-- Catalog returns (optional, left‑joined)
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN time_dim t_cr
  ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk

-- Inventory information
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w_inv
  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk

-- Web sales and related dimensions
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws
  ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk

GROUP BY GROUPING SETS (
    (d_sold.d_year, i.i_category, s.s_store_name),
    (d_sold.d_year, i.i_category),
    (d_sold.d_year),
    ()
)
LIMIT 100
