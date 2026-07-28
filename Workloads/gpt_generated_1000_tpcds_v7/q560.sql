WITH
  -- date aliases for different roles
  d_sold   AS (SELECT * FROM date_dim),
  d_ship   AS (SELECT * FROM date_dim),
  d_cr_ret AS (SELECT * FROM date_dim),
  d_cp_start AS (SELECT * FROM date_dim),
  d_cp_end   AS (SELECT * FROM date_dim),
  d_sr_ret AS (SELECT * FROM date_dim)
SELECT
  i.i_brand,
  cc.cc_name,
  w.w_state,
  sm.sm_type,
  d_sold.d_year               AS sold_year,
  SUM(ws.ws_net_profit)      AS total_net_profit,
  COUNT(DISTINCT ws.ws_order_number) AS orders,
  SUM(cr.cr_return_amount)   AS total_catalog_return_amount,
  SUM(sr.sr_return_amt)      AS total_store_return_amount
FROM web_sales ws
-- web_sales date dimensions
JOIN d_sold      ON ws.ws_sold_date_sk  = d_sold.d_date_sk
JOIN d_ship      ON ws.ws_ship_date_sk  = d_ship.d_date_sk
-- core dimensions
JOIN item i               ON ws.ws_item_sk        = i.i_item_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm          ON ws.ws_ship_mode_sk  = sm.sm_ship_mode_sk
JOIN warehouse w           ON ws.ws_warehouse_sk  = w.w_warehouse_sk
-- catalog returns and its dimensions
JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
JOIN d_cr_ret               ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN d_cp_start            ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN d_cp_end              ON cp.cp_end_date_sk   = d_cp_end.d_date_sk
-- store returns and its dimensions
JOIN store_returns sr      ON sr.sr_item_sk = i.i_item_sk
JOIN d_sr_ret               ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'barprically'
GROUP BY
  i.i_brand,
  cc.cc_name,
  w.w_state,
  sm.sm_type,
  d_sold.d_year
ORDER BY total_net_profit DESC
LIMIT 10
