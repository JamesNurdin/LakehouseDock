WITH filtered AS (
  SELECT
    s.s_store_id               AS store_id,
    s.s_city                  AS city,
    s.s_state                 AS state,
    d.d_year                  AS year,
    cc.cc_market_manager      AS market_manager,
    sm.sm_type                AS ship_type,
    r.r_reason_desc           AS reason_desc,
    wp.wp_url                 AS page_url,
    we.web_name               AS web_name,
    SUM(ss.ss_net_paid)               AS total_store_sales,
    SUM(COALESCE(sr.sr_net_loss, 0))  AS total_store_return_loss,
    SUM(COALESCE(cr.cr_net_loss, 0))  AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))  AS total_web_return_loss,
    SUM(ws.ws_net_profit)              AS total_web_sales_profit
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = ss.ss_ticket_number
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN web_sales ws
    ON ws.ws_order_number = ss.ss_ticket_number
   AND ws.ws_item_sk = ss.ss_item_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'TN'
    AND cc.cc_market_manager = 'Kevin Damico'
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc LIKE '%Damaged%'
  GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    d.d_year,
    cc.cc_market_manager,
    sm.sm_type,
    r.r_reason_desc,
    wp.wp_url,
    we.web_name
)
SELECT
  store_id,
  city,
  state,
  year,
  market_manager,
  ship_type,
  reason_desc,
  page_url,
  web_name,
  total_store_sales,
  total_store_return_loss,
  total_catalog_return_loss,
  total_web_return_loss,
  total_web_sales_profit,
  RANK() OVER (PARTITION BY year ORDER BY total_store_sales DESC) AS sales_rank
FROM filtered
ORDER BY sales_rank
LIMIT 100
