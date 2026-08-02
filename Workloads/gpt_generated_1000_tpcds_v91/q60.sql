WITH base_data AS (
  SELECT
    i.i_category,
    s.s_state,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    cr.cr_return_amount,
    cr.cr_net_loss,
    p.p_discount_active,
    td_sr.t_hour,
    dd_cr.d_date,
    CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator,
    i.i_item_id
  FROM catalog_returns cr
  JOIN date_dim dd_cr ON cr.cr_returned_date_sk = dd_cr.d_date_sk
  JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN date_dim dd_sr ON sr.sr_returned_date_sk = dd_sr.d_date_sk
  JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
  JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
  JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
  JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim dd_sclosed ON s.s_closed_date_sk = dd_sclosed.d_date_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = dd_sr.d_date_sk
  JOIN date_dim dd_wp_access ON wp.wp_access_date_sk = dd_wp_access.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = dd_cr.d_date_sk
  JOIN date_dim dd_ws_close ON ws.web_close_date_sk = dd_ws_close.d_date_sk
  WHERE i.i_category IN ('Sports', 'Books')
    AND dd_cr.d_date = DATE '2002-01-01'
    AND td_sr.t_hour BETWEEN 9 AND 17
    AND sr.sr_return_quantity > 2
    AND s.s_state = 'TX'
    AND p.p_discount_active = 'Y'
    AND w.w_state = 'CA'
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_discount_active = 'Y'
        AND p2.p_cost > 100
    )
),
aggregated AS (
  SELECT
    i_category,
    s_state,
    SUM(sr_return_quantity) AS total_return_qty,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(cr_return_amount) AS total_cr_return_amount
  FROM base_data
  GROUP BY ROLLUP(i_category, s_state)
)
SELECT
  i_category,
  s_state,
  total_return_qty,
  total_cr_return_amount,
  total_net_loss,
  CASE WHEN total_net_loss > 0 THEN 'Overall Loss' ELSE 'Overall Gain' END AS net_loss_flag,
  DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY i_category, s_state
LIMIT 100
