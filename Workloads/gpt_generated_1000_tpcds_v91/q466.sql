WITH intersect_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
)
SELECT
    d.d_year,
    s.s_store_name,
    sm.sm_carrier,
    w.w_country,
    ib.ib_upper_bound,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    MIN(cr.cr_return_quantity) AS min_return_quantity,
    MAX(cr.cr_return_quantity) AS max_return_quantity,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS catalog_return_rank
FROM catalog_returns cr
JOIN intersect_orders io ON cr.cr_order_number = io.cr_order_number
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_ship_date_sk = d.d_date_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN household_demographics hd_wr_ret ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE d.d_year = 2001
  AND t.t_am_pm = 'PM'
  AND s.s_state = 'CA'
  AND sm.sm_carrier = 'UPS'
  AND w.w_country = 'United States'
  AND ib.ib_lower_bound >= 50000
GROUP BY d.d_year, s.s_store_name, sm.sm_carrier, w.w_country, ib.ib_upper_bound
ORDER BY d.d_year, total_catalog_return_amount DESC
LIMIT 100
