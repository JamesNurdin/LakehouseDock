WITH base AS (
  SELECT
    i.i_category,
    d_sold.d_year AS d_year,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) AS net_profit
  FROM store_sales ss
  JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
  LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  LEFT JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_cr_return
    ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
  LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
  LEFT JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
  LEFT JOIN customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
  LEFT JOIN customer c_return
    ON cr.cr_returning_customer_sk = c_return.c_customer_sk
  LEFT JOIN customer_demographics cd_refund
    ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  LEFT JOIN customer_demographics cd_return
    ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
  LEFT JOIN customer c_refund_wr
    ON wr.wr_refunded_customer_sk = c_refund_wr.c_customer_sk
  LEFT JOIN customer c_return_wr
    ON wr.wr_returning_customer_sk = c_return_wr.c_customer_sk
  LEFT JOIN customer_demographics cd_refund_wr
    ON wr.wr_refunded_cdemo_sk = cd_refund_wr.cd_demo_sk
  LEFT JOIN customer_demographics cd_return_wr
    ON wr.wr_returning_cdemo_sk = cd_return_wr.cd_demo_sk
  WHERE d_sold.d_year = 2001
  GROUP BY i.i_category, d_sold.d_year
)
SELECT
  i_category,
  d_year,
  total_store_profit,
  total_web_profit,
  total_store_return_loss,
  total_web_return_loss,
  total_inventory,
  net_profit,
  RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
FROM base
ORDER BY net_profit DESC
LIMIT 100
