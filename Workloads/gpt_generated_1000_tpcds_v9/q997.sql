SELECT
    s.s_state AS store_state,
    sm.sm_type AS ship_type,
    wsite.web_company_name AS web_company,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_refunded_cash) AS total_store_refunds,
    SUM(wr.wr_refunded_cash) AS total_web_refunds,
    (SUM(ss.ss_ext_sales_price) - SUM(sr.sr_refunded_cash) + SUM(ws.ws_ext_sales_price) - SUM(wr.wr_refunded_cash)) AS net_sales,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    AVG(ws.ws_quantity) AS avg_web_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
    (SELECT SUM(ss2.ss_ext_sales_price) FROM store_sales ss2) AS overall_store_sales_total
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_addr_sk = ca_ss.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca_ss.ca_address_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_refunded_addr_sk = ca_ss.ca_address_sk
    AND wr.wr_returning_addr_sk = ca_ss.ca_address_sk
WHERE sm.sm_type = 'EXPRESS'
  AND s.s_state = 'CA'
  AND wsite.web_company_name = 'able'
  AND ss.ss_net_paid_inc_tax > 1000
GROUP BY ROLLUP (s.s_state, sm.sm_type, wsite.web_company_name)
LIMIT 100
