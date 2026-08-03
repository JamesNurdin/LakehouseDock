WITH
  agg_store_sales AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_quantity
    FROM tpcds.store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451555
    GROUP BY ss.ss_item_sk
  )
SELECT
  c.c_customer_id,
  i.i_item_id,
  i.i_category,
  cp.cp_department,
  agg.total_sales,
  SUM(sr.sr_return_quantity) AS total_return_qty,
  RANK() OVER (PARTITION BY i.i_category ORDER BY agg.total_sales DESC) AS category_sales_rank,
  CASE WHEN r.r_reason_desc = 'Damaged' THEN 'DEFECT' ELSE 'OK' END AS return_status,
  cr.cr_return_amount,
  ws.ws_net_profit,
  sm2.sm_carrier,
  cc.cc_state,
  td.t_hour
FROM agg_store_sales agg
JOIN tpcds.item i
  ON agg.ss_item_sk = i.i_item_sk
JOIN tpcds.store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
JOIN tpcds.time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.catalog_returns cr
  ON i.i_item_sk = cr.cr_item_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.reason r2
  ON cr.cr_reason_sk = r2.r_reason_sk
JOIN tpcds.ship_mode sm2
  ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN tpcds.web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON i.i_item_sk = wr.wr_item_sk
JOIN tpcds.reason r3
  ON wr.wr_reason_sk = r3.r_reason_sk
JOIN tpcds.ship_mode sm3
  ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
WHERE i.i_category = 'Electronics'
  AND cc.cc_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
  AND cc.cc_call_center_sk IN (
        SELECT cr2.cr_call_center_sk
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_return_amount > 1000
      )
  AND cp.cp_catalog_page_sk IN (
        SELECT cd2.cd_demo_sk
        FROM tpcds.customer_demographics cd2
        WHERE cd2.cd_gender = 'F'
      )
GROUP BY
  c.c_customer_id,
  i.i_item_id,
  i.i_category,
  cp.cp_department,
  agg.total_sales,
  r.r_reason_desc,
  cr.cr_return_amount,
  ws.ws_net_profit,
  sm2.sm_carrier,
  cc.cc_state,
  td.t_hour

UNION DISTINCT

SELECT
  c.c_customer_id,
  i.i_item_id,
  i.i_category,
  cp.cp_department,
  agg.total_sales,
  SUM(sr.sr_return_quantity) AS total_return_qty,
  DENSE_RANK() OVER (PARTITION BY i.i_category ORDER BY agg.total_sales ASC) AS category_sales_rank,
  CASE WHEN r.r_reason_desc = 'Damaged' THEN 'DEFECT' ELSE 'OK' END AS return_status,
  cr.cr_return_amount,
  ws.ws_net_profit,
  sm2.sm_carrier,
  cc.cc_state,
  td.t_hour
FROM agg_store_sales agg
JOIN tpcds.item i
  ON agg.ss_item_sk = i.i_item_sk
JOIN tpcds.store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
JOIN tpcds.time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.catalog_returns cr
  ON i.i_item_sk = cr.cr_item_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.reason r2
  ON cr.cr_reason_sk = r2.r_reason_sk
JOIN tpcds.ship_mode sm2
  ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN tpcds.web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON i.i_item_sk = wr.wr_item_sk
JOIN tpcds.reason r3
  ON wr.wr_reason_sk = r3.r_reason_sk
JOIN tpcds.ship_mode sm3
  ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
WHERE i.i_category = 'Books'
  AND cc.cc_state = 'NY'
  AND td.t_hour BETWEEN 13 AND 20
  AND cc.cc_call_center_sk IN (
        SELECT cr2.cr_call_center_sk
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_return_amount > 500
      )
  AND cp.cp_catalog_page_sk IN (
        SELECT cd2.cd_demo_sk
        FROM tpcds.customer_demographics cd2
        WHERE cd2.cd_gender = 'M'
      )
GROUP BY
  c.c_customer_id,
  i.i_item_id,
  i.i_category,
  cp.cp_department,
  agg.total_sales,
  r.r_reason_desc,
  cr.cr_return_amount,
  ws.ws_net_profit,
  sm2.sm_carrier,
  cc.cc_state,
  td.t_hour

ORDER BY
  category_sales_rank,
  total_sales DESC
