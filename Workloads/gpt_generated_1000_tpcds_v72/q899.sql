WITH joined_data AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    d1.d_year,
    sr.sr_net_loss,
    ws.ws_net_profit,
    ws.ws_net_paid_inc_ship
  FROM store_returns sr
  JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer cu ON sr.sr_customer_sk = cu.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d1.d_date_sk
    AND cr.cr_returned_time_sk = t1.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
    AND ws.ws_sold_time_sk = t1.t_time_sk
    AND ws.ws_bill_customer_sk = cu.c_customer_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d1.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND ws.ws_net_paid_inc_ship > 1000
),
agg_data AS (
  SELECT
    s_store_id,
    s_store_name,
    d_year,
    SUM(sr_net_loss) AS total_return_loss,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(ws_net_paid_inc_ship) AS total_paid_inc_ship
  FROM joined_data
  GROUP BY s_store_id, s_store_name, d_year
)
SELECT
  s_store_id,
  s_store_name,
  d_year,
  total_return_loss,
  total_web_profit,
  total_paid_inc_ship,
  ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_loss DESC) AS loss_rank,
  CASE WHEN total_web_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
  (
    SELECT AVG(ws2.ws_net_profit)
    FROM web_sales ws2
    WHERE ws2.ws_sold_date_sk = (
      SELECT d2.d_date_sk
      FROM date_dim d2
      WHERE d2.d_year = 2001
    )
  ) AS avg_yearly_profit
FROM agg_data
ORDER BY total_return_loss DESC
LIMIT 100
