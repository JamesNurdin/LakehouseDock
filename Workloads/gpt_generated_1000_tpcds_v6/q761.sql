/*
  Goal: Summarize the financial impact of catalog returns linked to specific call centers, ship modes, and income bands, and compare it with web sales performance for the same household demographics.
*/
SELECT
    cc.cc_name,
    sm.sm_type,
    ib.ib_lower_bound,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN income_band ib
  ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
  ON ws.ws_bill_hdemo_sk = hd_ref.hd_demo_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE cc.cc_manager = 'Travis Wilson'
  AND sm.sm_type = 'OVERNIGHT'
  AND ib.ib_lower_bound >= 50000
GROUP BY
    cc.cc_name,
    sm.sm_type,
    ib.ib_lower_bound
ORDER BY total_return_amount DESC
LIMIT 100
