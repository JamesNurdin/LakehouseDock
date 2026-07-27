WITH
  ss AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_ticket_number,
      SUM(ss.ss_net_paid)      AS store_net_paid,
      SUM(ss.ss_net_profit)   AS store_net_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    GROUP BY
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_ticket_number
  ),
  cr_distinct AS (
    SELECT DISTINCT
      cr.cr_returned_date_sk,
      cr.cr_call_center_sk,
      cr.cr_warehouse_sk
    FROM catalog_returns cr
  ),
  cr_total AS (
    SELECT
      cr_returned_date_sk,
      SUM(cr_return_amount) AS cr_total_return_amount
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
  ),
  ws_total AS (
    SELECT
      ws_sold_date_sk,
      SUM(ws_net_paid) AS ws_total_net_paid
    FROM web_sales
    GROUP BY ws_sold_date_sk
  ),
  wr_total AS (
    SELECT
      wr_returned_date_sk,
      SUM(wr_net_loss) AS wr_total_net_loss
    FROM web_returns
    GROUP BY wr_returned_date_sk
  )
SELECT
  d_sold.d_year,
  s.s_store_name,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ss.store_net_paid,
  ws_total.ws_total_net_paid,
  cr_total.cr_total_return_amount,
  wr_total.wr_total_net_loss,
  ss.distinct_tickets
FROM ss
JOIN date_dim d_sold        ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s                ON ss.ss_store_sk    = s.s_store_sk
JOIN customer c             ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk   = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk   = hd.hd_demo_sk
JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr  ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN call_center cc    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w       ON cr.cr_warehouse_sk   = w.w_warehouse_sk
LEFT JOIN web_sales ws      ON ws.ws_sold_date_sk = d_sold.d_date_sk
LEFT JOIN web_site we        ON ws.ws_web_site_sk   = we.web_site_sk
LEFT JOIN web_page wp        ON ws.ws_web_page_sk   = wp.wp_web_page_sk
LEFT JOIN web_returns wr    ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_ship        ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_ship    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
LEFT JOIN cr_total          ON cr_total.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN ws_total          ON ws_total.ws_sold_date_sk   = d_sold.d_date_sk
LEFT JOIN wr_total          ON wr_total.wr_returned_date_sk = d_sold.d_date_sk
ORDER BY d_sold.d_year DESC, s.s_store_name ASC
LIMIT 100
