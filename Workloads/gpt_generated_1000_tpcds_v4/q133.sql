WITH joined AS (
SELECT
  d.d_year,
  s.s_store_name,
  p.p_promo_name,
  hd.hd_buy_potential,
  ca.ca_state,
  COUNT(DISTINCT ss.ss_ticket_number)                      AS store_sales_txns,
  SUM(ss.ss_sales_price)                                 AS total_store_sales,
  SUM(ss.ss_net_profit)                                  AS total_store_profit,
  COUNT(DISTINCT ws.ws_order_number)                     AS web_sales_orders,
  SUM(ws.ws_sales_price)                                 AS total_web_sales,
  SUM(ws.ws_net_profit)                                  AS total_web_profit,
  COUNT(DISTINCT cr.cr_order_number)                     AS catalog_return_cnt,
  SUM(cr.cr_return_amount)                               AS total_catalog_return,
  COUNT(DISTINCT sr.sr_ticket_number)                    AS store_return_cnt,
  SUM(sr.sr_return_amt)                                  AS total_store_return,
  COUNT(DISTINCT inv.inv_item_sk)                        AS inventory_item_cnt,
  SUM(inv.inv_quantity_on_hand)                          AS total_inventory_qty,
  SUM(cc.cc_tax_percentage)                              AS total_cc_tax_pct
FROM date_dim d
-- Store sales and its dimensions
JOIN store_sales ss          ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s                ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t             ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p            ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca    ON ss.ss_addr_sk = ca.ca_address_sk
-- Store closed date (different alias of date_dim)
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
-- Web sales and its dimensions
JOIN web_sales ws           ON ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w            ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- Catalog returns and its dimensions
JOIN catalog_returns cr     ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc         ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm2          ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN warehouse w2           ON cr.cr_warehouse_sk = w2.w_warehouse_sk
-- Store returns linked to store sales and store
JOIN store_returns sr       ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_store_sk = s.s_store_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
-- Inventory linked to the same warehouse used by web sales
JOIN inventory inv          ON inv.inv_date_sk = d.d_date_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
-- Income band via household demographics
JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
-- Promotion start/end dates (different aliases of date_dim)
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end   ON p.p_end_date_sk = d_promo_end.d_date_sk
-- Call center open/closed dates (different aliases of date_dim)
JOIN date_dim d_cc_closed   ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open     ON cc.cc_open_date_sk = d_cc_open.d_date_sk
-- Web page creation/access dates (different aliases of date_dim)
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access   ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d.d_year = 2001
  AND ca.ca_country = 'United States'
GROUP BY
  d.d_year,
  s.s_store_name,
  p.p_promo_name,
  hd.hd_buy_potential,
  ca.ca_state
)
SELECT *
FROM joined
ORDER BY total_store_sales DESC
LIMIT 100
