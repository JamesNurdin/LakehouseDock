WITH per_group AS (
  SELECT
    cd.cd_gender,
    hd.hd_buy_potential,
    td.t_sub_shift,
    cp.cp_type,
    p.p_channel_tv,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) AS total_web_profit
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE td.t_hour IN (7, 10, 1)
    AND cp.cp_type = 'monthly'
    AND cc.cc_state = 'CA'
    AND i.inv_quantity_on_hand > 1000
    AND ws.ws_net_paid_inc_ship_tax > 5000
    AND sr.sr_return_quantity >= 2
  GROUP BY CUBE (cd.cd_gender, hd.hd_buy_potential, td.t_sub_shift, cp.cp_type, p.p_channel_tv)
)
SELECT
  AVG(total_return_loss) AS avg_return_loss,
  AVG(total_web_profit) AS avg_web_profit,
  COUNT(*) AS group_count
FROM per_group
WHERE total_return_loss > 0
HAVING COUNT(*) > 10
LIMIT 100
