SELECT
  s.s_store_id,
  s.s_city,
  sm.sm_type AS ship_mode_type,
  ws_site.web_state,
  SUM(ws.ws_net_paid) AS total_net_paid,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
  MIN(ws.ws_sales_price) AS min_sales_price,
  MAX(ws.ws_sales_price) AS max_sales_price,
  SUM(sr.sr_return_amt) AS total_return_amount,
  COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
  ib.ib_upper_bound,
  cd.cd_gender,
  hd.hd_buy_potential,
  u.part AS suite_part
FROM
  web_sales ws
  RIGHT OUTER JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  FULL OUTER JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  FULL OUTER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN UNNEST(split(ws_site.web_suite_number, ' ')) AS u(part) ON true
WHERE
  d.d_year = 1999
  AND i.i_current_price > 50
  AND p.p_discount_active = 'Y'
  AND ws_site.web_suite_number LIKE 'Suite %'
  AND ib.ib_upper_bound <= 50000
  AND cc.cc_state = 'TX'
  AND cp.cp_catalog_number IN (10, 20)
GROUP BY
  s.s_store_id,
  s.s_city,
  sm.sm_type,
  ws_site.web_state,
  ib.ib_upper_bound,
  cd.cd_gender,
  hd.hd_buy_potential,
  u.part
HAVING
  SUM(ws.ws_net_paid) > 100000
ORDER BY
  total_net_paid DESC
LIMIT 100
