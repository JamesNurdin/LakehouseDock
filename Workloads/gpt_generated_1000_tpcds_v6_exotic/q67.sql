-- Goal: Summarize revenue and loss metrics across catalog, store, and web channels by return year and return reason.
-- The query joins all 14 TPC‑DS tables using only the permitted join keys, re‑using the date_dim and customer_address tables under different aliases.
SELECT
    d_cr.d_year                                     AS return_year,
    r_cr.r_reason_desc                              AS return_reason,
    SUM(cr.cr_return_amount)                       AS total_catalog_return_amount,
    SUM(sr.sr_net_loss)                            AS total_store_return_net_loss,
    SUM(wr.wr_net_loss)                            AS total_web_return_net_loss,
    SUM(ss.ss_net_paid)                            AS total_store_sales_net_paid,
    SUM(ws.ws_net_paid)                            AS total_web_sales_net_paid
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN item i_cr
  ON cr.cr_item_sk = i_cr.i_item_sk
JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr
  ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer_address ca_refunded
  ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk

-- Store channel
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_cr.d_date_sk
JOIN time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i_ss
  ON ss.ss_item_sk = i_ss.i_item_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk

JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN item i_sr
  ON sr.sr_item_sk = i_sr.i_item_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN store s_sr
  ON sr.sr_store_sk = s_sr.s_store_sk
JOIN store_sales ss2
  ON sr.sr_ticket_number = ss2.ss_ticket_number

-- Web channel
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_cr.d_date_sk
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN item i_ws
  ON ws.ws_item_sk = i_ws.i_item_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk

JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN item i_wr
  ON wr.wr_item_sk = i_wr.i_item_sk
JOIN customer_address ca_wr_refunded
  ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning
  ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp_wr
  ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
JOIN web_sales ws2
  ON wr.wr_order_number = ws2.ws_order_number

GROUP BY ROLLUP (d_cr.d_year, r_cr.r_reason_desc)
ORDER BY d_cr.d_year ASC, r_cr.r_reason_desc ASC
LIMIT 100
