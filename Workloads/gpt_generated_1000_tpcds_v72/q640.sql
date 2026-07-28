WITH
  store_sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_item_sk,
      ss.ss_ticket_number,
      SUM(ss.ss_net_paid) AS store_sales_net_paid,
      COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    GROUP BY
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_item_sk,
      ss.ss_ticket_number
  ),

  catalog_sales_agg AS (
    SELECT
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_order_number,
      cs.cs_item_sk,
      SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
      COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    GROUP BY
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_order_number,
      cs.cs_item_sk
  ),

  web_sales_agg AS (
    SELECT
      ws.ws_web_site_sk,
      ws.ws_web_page_sk,
      ws.ws_ship_mode_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_order_number,
      ws.ws_item_sk,
      SUM(ws.ws_net_paid) AS web_sales_net_paid,
      COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    GROUP BY
      ws.ws_web_site_sk,
      ws.ws_web_page_sk,
      ws.ws_ship_mode_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_order_number,
      ws.ws_item_sk
  )

SELECT
  d.d_year,
  s.s_store_name,
  i.i_brand,
  CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END AS income_category,
  ca.catalog_sales_net_paid,
  ss.store_sales_net_paid,
  ws.web_sales_net_paid,
  COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM
  store_sales_agg ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN catalog_sales_agg ca ON ca.cs_sold_date_sk = ss.ss_sold_date_sk
                               AND ca.cs_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_page cp ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm_cat ON ca.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = ca.cs_order_number
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN web_sales_agg ws ON ws.ws_sold_date_sk = ss.ss_sold_date_sk
                              AND ws.ws_item_sk = ss.ss_item_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN ship_mode sm_web ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
WHERE
  d.d_year = 2001
  AND s.s_state = 'TX'
  AND ib.ib_upper_bound >= 100000
  AND i.i_brand = 'Brand#12'
  AND cp.cp_department = 'Sports'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY
  d.d_year,
  s.s_store_name,
  i.i_brand,
  CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END,
  ca.catalog_sales_net_paid,
  ss.store_sales_net_paid,
  ws.web_sales_net_paid
ORDER BY
  d.d_year DESC,
  ss.store_sales_net_paid DESC
LIMIT 100
