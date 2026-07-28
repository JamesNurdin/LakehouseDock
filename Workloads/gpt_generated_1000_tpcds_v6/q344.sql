WITH base AS (
  SELECT
    s.s_city,
    d.d_year,
    cp.cp_department,
    ss.ss_net_paid,
    cs.cs_net_paid,
    ws.ws_net_paid,
    ss.ss_ticket_number,
    cs.cs_order_number,
    ws.ws_order_number
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN inventory i ON i.inv_date_sk = d.d_date_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_returned_date_sk = d.d_date_sk
  WHERE
    d.d_year = 2001
    AND s.s_city = 'Fairview'
    AND cc.cc_name = 'Northwest Call Center'
    AND cp.cp_type = 'Promotion'
    AND r.r_reason_desc = 'Customer Not Home'
    AND i.inv_quantity_on_hand > 1000
    AND t.t_hour = 14
    AND c.c_preferred_cust_flag = 'Y'
)
SELECT
  s_city,
  d_year,
  cp_department,
  SUM(ss_net_paid)          AS total_store_net_paid,
  SUM(cs_net_paid)          AS total_catalog_net_paid,
  SUM(ws_net_paid)          AS total_web_net_paid,
  COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
  COUNT(DISTINCT cs_order_number)  AS catalog_order_cnt,
  COUNT(DISTINCT ws_order_number)  AS web_order_cnt
FROM base
GROUP BY ROLLUP (s_city, d_year, cp_department)
ORDER BY
  s_city,
  d_year DESC,
  cp_department
