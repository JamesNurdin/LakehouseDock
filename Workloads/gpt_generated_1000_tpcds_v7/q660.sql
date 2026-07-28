WITH
    cr_hd AS (
        SELECT
            cr.*, 
            hd_ref.hd_income_band_sk AS refunded_income_band_sk
        FROM catalog_returns cr
        JOIN household_demographics hd_ref
          ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    )
SELECT
    p.p_promo_id,
    p.p_channel_event,
    hd_cust.hd_income_band_sk AS customer_income_band,
    SUM(sr.sr_net_loss)                         AS total_store_net_loss,
    SUM(cr_hd.cr_net_loss)                      AS total_catalog_net_loss,
    SUM(ws.ws_net_profit)                       AS total_web_profit,
    COUNT(DISTINCT sr.sr_ticket_number)        AS store_return_cnt,
    COUNT(DISTINCT ws.ws_order_number)         AS web_order_cnt
FROM store_returns sr
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd_cust
  ON c.c_current_hdemo_sk = hd_cust.hd_demo_sk
JOIN cr_hd
  ON cr_hd.cr_returning_customer_sk = c.c_customer_sk
JOIN catalog_page cp
  ON cr_hd.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cr
  ON cr_hd.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
WHERE p.p_channel_event = 'N'
GROUP BY
    p.p_promo_id,
    p.p_channel_event,
    hd_cust.hd_income_band_sk
