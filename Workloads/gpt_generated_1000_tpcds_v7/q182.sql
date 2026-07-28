WITH base_time AS (
    SELECT t_time_sk, t_hour
    FROM tpcds.time_dim
)
SELECT
    td.t_hour AS hour_of_day,
    cp.cp_department AS department,
    p_cs.p_promo_name AS promo_name,
    SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
    SUM(cr.cr_return_amount) AS catalog_returns_amount,
    SUM(ss.ss_net_paid) AS store_sales_net_paid,
    SUM(sr.sr_return_amt) AS store_returns_amount,
    SUM(ws.ws_net_paid) AS web_sales_net_paid,
    SUM(wr.wr_return_amt) AS web_returns_amount,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit
FROM tpcds.time_dim td
-- Catalog sales branch
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.promotion p_cs
  ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
 AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
 AND cr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN tpcds.customer_address ca_cr_refund
  ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
LEFT JOIN tpcds.customer_address ca_cr_return
  ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
-- Store sales branch
JOIN tpcds.store_sales ss
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN tpcds.promotion p_ss
  ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN tpcds.customer_address ca_store
  ON ss.ss_addr_sk = ca_store.ca_address_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_return_time_sk = td.t_time_sk
LEFT JOIN tpcds.customer_address ca_sr_addr
  ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
-- Web sales branch
JOIN tpcds.web_sales ws
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.promotion p_ws
  ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN tpcds.customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN tpcds.customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
LEFT JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
 AND wr.wr_returned_time_sk = td.t_time_sk
LEFT JOIN tpcds.customer_address ca_wr_refund
  ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
LEFT JOIN tpcds.customer_address ca_wr_return
  ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
GROUP BY
    td.t_hour,
    cp.cp_department,
    p_cs.p_promo_name
ORDER BY catalog_profit DESC
LIMIT 100
