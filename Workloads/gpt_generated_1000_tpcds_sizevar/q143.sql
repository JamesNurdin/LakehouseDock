SELECT
  d.d_year AS year,
  r.r_reason_desc AS return_reason,
  sm.sm_type AS ship_mode,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_catalog_sales,
  SUM(cr.cr_return_amount) AS total_catalog_returns,
  SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_sales,
  SUM(sr.sr_return_amt) AS total_store_returns
FROM
  catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
WHERE
  d.d_year = 2001
  AND r.r_reason_desc = 'Did not like the color'
  AND sm.sm_type = 'AIR'
  AND cs.cs_order_number NOT IN (
    SELECT ws2.ws_order_number FROM web_sales ws2
  )
GROUP BY
  d.d_year,
  r.r_reason_desc,
  sm.sm_type
ORDER BY
  total_catalog_sales DESC
LIMIT 100
