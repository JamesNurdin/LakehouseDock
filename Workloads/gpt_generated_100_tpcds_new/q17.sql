SELECT
    d.d_date,
    d.d_year,
    cp.cp_catalog_number,
    cc.cc_name,
    sm.sm_type,
    SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt) AS total_store_returns,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS row_num
FROM tpcds.date_dim d
JOIN tpcds.call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN tpcds.promotion p
  ON p.p_start_date_sk = d.d_date_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN tpcds.store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND cp.cp_catalog_number IN (4, 9, 11)
  AND cd.cd_credit_rating = 'Good'
  AND sm.sm_type = 'AIR'
  AND p.p_discount_active = 'Y'
  AND cc.cc_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY d.d_date, d.d_year, cp.cp_catalog_number, cc.cc_name, sm.sm_type
ORDER BY total_catalog_sales_profit DESC
LIMIT 100
