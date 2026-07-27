WITH
  d_sold AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_ship AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_ret_store AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_ret_catalog AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_ret_web AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_store_close AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_cc_open AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_cc_close AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_cp_start AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_cp_end AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_promo_start AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_promo_end AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  )
SELECT
  s.s_store_name,
  d_sold.d_year,
  ws.web_name,
  SUM(ss.ss_net_profit)                     AS total_store_profit,
  SUM(sr.sr_net_loss)                       AS total_store_return_loss,
  SUM(cr.cr_net_loss)                       AS total_catalog_return_loss,
  SUM(wr.wr_net_loss)                       AS total_web_return_loss,
  COUNT(DISTINCT ss.ss_customer_sk)          AS distinct_customers,
  AVG(p.p_cost)                              AS avg_promo_cost,
  COUNT(DISTINCT sm.sm_ship_mode_id)         AS distinct_ship_modes,
  MAX(cc.cc_tax_percentage)                 AS max_call_center_tax_pct,
  MIN(ib.ib_lower_bound)                    AS min_income_lower_bound
FROM store_sales ss
JOIN d_sold          ON ss.ss_sold_date_sk      = d_sold.d_date_sk
JOIN store s          ON ss.ss_store_sk          = s.s_store_sk
JOIN d_store_close   ON s.s_closed_date_sk      = d_store_close.d_date_sk
JOIN promotion p      ON ss.ss_promo_sk          = p.p_promo_sk
JOIN d_promo_start   ON p.p_start_date_sk       = d_promo_start.d_date_sk
JOIN d_promo_end     ON p.p_end_date_sk         = d_promo_end.d_date_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib   ON hd.hd_income_band_sk   = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk      = ca.ca_address_sk
JOIN catalog_sales cs ON cs.cs_promo_sk          = p.p_promo_sk
JOIN d_ship          ON cs.cs_ship_date_sk      = d_ship.d_date_sk
JOIN call_center cc  ON cs.cs_call_center_sk    = cc.cc_call_center_sk
JOIN d_cc_open       ON cc.cc_open_date_sk      = d_cc_open.d_date_sk
JOIN d_cc_close      ON cc.cc_closed_date_sk    = d_cc_close.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
JOIN d_cp_start      ON cp.cp_start_date_sk    = d_cp_start.d_date_sk
JOIN d_cp_end        ON cp.cp_end_date_sk      = d_cp_end.d_date_sk
JOIN ship_mode sm    ON cs.cs_ship_mode_sk      = sm.sm_ship_mode_sk
JOIN store_returns sr ON sr.sr_ticket_number   = ss.ss_ticket_number
                       AND sr.sr_store_sk   = s.s_store_sk
JOIN d_ret_store     ON sr.sr_returned_date_sk = d_ret_store.d_date_sk
JOIN catalog_returns cr ON cr.cr_order_number   = cs.cs_order_number
                           AND cr.cr_item_sk   = cs.cs_item_sk
JOIN d_ret_catalog   ON cr.cr_returned_date_sk = d_ret_catalog.d_date_sk
JOIN web_returns wr ON wr.wr_order_number      = cs.cs_order_number
JOIN d_ret_web      ON wr.wr_returned_date_sk  = d_ret_web.d_date_sk
JOIN web_site ws    ON ws.web_open_date_sk    = d_sold.d_date_sk  -- using the same date_dim alias for the open date
GROUP BY
  s.s_store_name,
  d_sold.d_year,
  ws.web_name
ORDER BY total_store_profit DESC
LIMIT 100
