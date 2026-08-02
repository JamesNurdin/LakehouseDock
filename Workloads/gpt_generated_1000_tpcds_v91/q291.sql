(
SELECT
    i.i_category,
    i.i_formulation,
    i.i_size,
    hd.hd_income_band_sk,
    w.w_state,
    p.p_promo_id,
    SUM(ws.ws_net_paid) AS sum_ws_net_paid,
    SUM(ss.ss_net_paid) AS sum_ss_net_paid,
    SUM(sr.sr_refunded_cash) AS sum_sr_refunded_cash,
    COUNT(DISTINCT c.c_customer_id) AS cnt_customers,
    AVG(ws.ws_quantity) AS avg_ws_quantity,
    MIN(i.i_current_price) AS min_price,
    MAX(i.i_current_price) AS max_price
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE i.i_category = 'Books'
  AND i.i_formulation = 'thistle3370503164308'
  AND i.i_size = 'small'
  AND p.p_channel_email = 'N'
  AND p.p_channel_dmail = 'Y'
GROUP BY i.i_category, i.i_formulation, i.i_size, hd.hd_income_band_sk, w.w_state, p.p_promo_id
HAVING SUM(ws.ws_net_paid) > 10000
)
EXCEPT
(
SELECT
    i.i_category,
    i.i_formulation,
    i.i_size,
    hd.hd_income_band_sk,
    w.w_state,
    p.p_promo_id,
    SUM(ws.ws_net_paid) AS sum_ws_net_paid,
    SUM(ss.ss_net_paid) AS sum_ss_net_paid,
    SUM(sr.sr_refunded_cash) AS sum_sr_refunded_cash,
    COUNT(DISTINCT c.c_customer_id) AS cnt_customers,
    AVG(ws.ws_quantity) AS avg_ws_quantity,
    MIN(i.i_current_price) AS min_price,
    MAX(i.i_current_price) AS max_price
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE i.i_category = 'Books'
  AND i.i_formulation = 'thistle3370503164308'
  AND i.i_size = 'small'
  AND p.p_channel_email = 'N'
  AND p.p_channel_dmail = 'Y'
  AND w.w_state = 'CA'
GROUP BY i.i_category, i.i_formulation, i.i_size, hd.hd_income_band_sk, w.w_state, p.p_promo_id
HAVING SUM(ws.ws_net_paid) > 20000
)
ORDER BY sum_ws_net_paid DESC
LIMIT 100
