WITH
    cr AS (SELECT * FROM catalog_returns),
    sr AS (SELECT * FROM store_returns),
    ws AS (SELECT * FROM web_sales)
SELECT
    d_cr.d_year AS year,
    cd_store.cd_gender AS gender,
    i.i_brand AS brand,
    sm_ship.sm_type AS ship_type,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT cr.cr_order_number) AS orders_cnt
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN ship_mode sm_ship
  ON cr.cr_ship_mode_sk = sm_ship.sm_ship_mode_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr
  ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer_demographics cd_store
  ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd_store
  ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN income_band ib
  ON hd_store.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
  ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_ws_open
  ON wsite.web_open_date_sk = d_ws_open.d_date_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p2
  ON ws.ws_promo_sk = p2.p_promo_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_department = cp.cp_department
      AND cp2.cp_catalog_number > 5
)
GROUP BY d_cr.d_year, cd_store.cd_gender, i.i_brand, sm_ship.sm_type
HAVING SUM(cr.cr_return_amount) > 10000
ORDER BY total_catalog_return DESC
LIMIT 100
