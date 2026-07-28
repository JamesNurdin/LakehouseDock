SELECT
  d_sr.d_year AS return_year,
  i.i_category AS item_category,
  s.s_state AS store_state,
  sm.sm_type AS ship_mode_type,
  r.r_reason_desc AS store_reason,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
  SUM(sr.sr_net_loss) AS store_net_loss,
  SUM(cr.cr_net_loss) AS catalog_net_loss,
  SUM(wr.wr_net_loss) AS web_net_loss,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  AVG(p.p_cost) AS avg_promo_cost,
  MIN(i.i_current_price) AS min_item_price,
  MAX(i.i_current_price) AS max_item_price
FROM store_returns sr
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sr.d_date_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
  AND p.p_start_date_sk <= d_sr.d_date_sk
  AND p.p_end_date_sk >= d_sr.d_date_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_returned_date_sk = d_sr.d_date_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_site ws ON ws.web_site_sk = ws.web_site_sk
JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE
  d_sr.d_year = 2001
  AND i.i_category = 'Sports'
  AND ca_sr.ca_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND p.p_channel_email = 'Y'
  AND s.s_number_employees > 200
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
          AND wp.wp_type = 'Content'
      )
GROUP BY
  d_sr.d_year,
  i.i_category,
  s.s_state,
  sm.sm_type,
  r.r_reason_desc
LIMIT 100
