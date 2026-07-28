WITH sub_a AS (
  SELECT
    d_cr.d_year AS year,
    sm_cr.sm_type AS ship_mode_type,
    ib_ref.ib_lower_bound AS income_lower,
    wh_cr.w_warehouse_name AS warehouse_name,
    web.web_name AS web_site_name,
    cr.cr_net_loss AS net_loss,
    ss.ss_net_paid AS ss_net_paid,
    ws.ws_net_paid AS ws_net_paid
  FROM catalog_returns cr
  JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  JOIN warehouse wh_cr ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
  JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
  JOIN store_sales ss ON ss.ss_customer_sk = c_ref.c_customer_sk
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
  JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN customer_demographics cd_return ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
  JOIN household_demographics hd_return ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c_ref.c_customer_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse wh_ws ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
  JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
  JOIN date_dim d_web_open ON web.web_open_date_sk = d_web_open.d_date_sk
  JOIN date_dim d_web_close ON web.web_close_date_sk = d_web_close.d_date_sk
  WHERE d_cr.d_year = 1998
),
sub_b AS (
  SELECT
    d_cr.d_year AS year,
    sm_cr.sm_type AS ship_mode_type,
    ib_ref.ib_lower_bound AS income_lower,
    wh_cr.w_warehouse_name AS warehouse_name,
    web.web_name AS web_site_name,
    cr.cr_net_loss AS net_loss,
    ss.ss_net_paid AS ss_net_paid,
    ws.ws_net_paid AS ws_net_paid
  FROM catalog_returns cr
  JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  JOIN warehouse wh_cr ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
  JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
  JOIN store_sales ss ON ss.ss_customer_sk = c_ref.c_customer_sk
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
  JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN customer_demographics cd_return ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
  JOIN household_demographics hd_return ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c_ref.c_customer_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse wh_ws ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
  JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
  JOIN date_dim d_web_open ON web.web_open_date_sk = d_web_open.d_date_sk
  JOIN date_dim d_web_close ON web.web_close_date_sk = d_web_close.d_date_sk
  WHERE d_cr.d_year = 1999
)
SELECT
  year,
  ship_mode_type,
  income_lower,
  warehouse_name,
  web_site_name,
  SUM(net_loss) AS total_net_loss,
  SUM(ss_net_paid) AS total_store_sales_paid,
  SUM(ws_net_paid) AS total_web_sales_paid,
  RANK() OVER (PARTITION BY year ORDER BY SUM(net_loss) DESC) AS loss_rank,
  SUM(SUM(net_loss)) OVER (ORDER BY year) AS cumulative_loss_by_year
FROM (
  SELECT * FROM sub_a
  UNION ALL
  SELECT * FROM sub_b
) u
GROUP BY year, ship_mode_type, income_lower, warehouse_name, web_site_name
ORDER BY year, total_net_loss DESC
