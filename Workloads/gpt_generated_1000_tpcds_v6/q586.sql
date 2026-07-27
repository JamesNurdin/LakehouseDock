WITH catalog_agg AS (
  SELECT
    d_cs.d_year AS year,
    'Catalog' AS channel,
    SUM(cs.cs_net_paid) AS total_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss
  FROM catalog_sales cs
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
  LEFT JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
  LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w_cs.w_warehouse_sk
   AND inv.inv_date_sk = d_cs.d_date_sk
  GROUP BY d_cs.d_year
),
store_agg AS (
  SELECT
    d_ss.d_year AS year,
    'Store' AS channel,
    SUM(ss.ss_net_paid) AS total_amount,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
  FROM store_sales ss
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  GROUP BY d_ss.d_year
),
web_agg AS (
  SELECT
    d_wr.d_year AS year,
    'Web' AS channel,
    SUM(wr.wr_return_amt) AS total_amount,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  GROUP BY d_wr.d_year
)
SELECT
  year,
  channel,
  total_amount,
  total_return_loss,
  RANK() OVER (PARTITION BY channel ORDER BY total_amount DESC) AS channel_rank
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
) u
ORDER BY year DESC, channel, total_amount DESC
LIMIT 100
