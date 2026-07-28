/*
  Goal: Summarize web sales revenue and returns by year, product brand, shipping carrier and store, while also exposing related call‑center and catalog page information.
*/
SELECT
    d_date.d_year,
    i.i_brand,
    sm.sm_carrier,
    s.s_store_name,
    COUNT(DISTINCT ws.ws_order_number)               AS order_cnt,
    SUM(ws.ws_net_paid)                              AS total_net_paid,
    AVG(ws.ws_ext_discount_amt)                     AS avg_discount,
    SUM(COALESCE(sr.sr_return_amt, 0))               AS total_return_amount,
    MIN(cc.cc_name)                                 AS any_call_center,
    MIN(cp.cp_type)                                 AS any_catalog_type
FROM tpcds.web_sales ws
JOIN tpcds.date_dim d_date
  ON ws.ws_sold_date_sk = d_date.d_date_sk
JOIN tpcds.time_dim t_time
  ON ws.ws_sold_time_sk = t_time.t_time_sk
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_returned_date_sk = d_date.d_date_sk
JOIN tpcds.customer_address ca
  ON ca.ca_address_sk = ws.ws_bill_addr_sk
JOIN tpcds.customer_demographics cd
  ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
JOIN tpcds.household_demographics hd
  ON hd.hd_demo_sk = ws.ws_bill_hdemo_sk
JOIN tpcds.store s
  ON s.s_store_sk = sr.sr_store_sk
LEFT JOIN tpcds.call_center cc
  ON cc.cc_closed_date_sk = d_date.d_date_sk
LEFT JOIN tpcds.catalog_page cp
  ON cp.cp_start_date_sk = d_date.d_date_sk
WHERE
    d_date.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND sm.sm_carrier = 'UPS'
GROUP BY
    d_date.d_year,
    i.i_brand,
    sm.sm_carrier,
    s.s_store_name
ORDER BY total_net_paid DESC
LIMIT 100
