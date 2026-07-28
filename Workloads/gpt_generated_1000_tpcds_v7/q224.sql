SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    p.p_promo_id,
    we.web_name,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ss.ss_net_paid) AS total_store_sales,
    AVG(sr.sr_refunded_cash) AS avg_refunded_cash,
    MIN(cr.cr_net_loss) AS min_net_loss,
    MAX(ws.ws_net_profit) AS max_web_profit
FROM store_sales ss
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_returns cr
  ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    ss.ss_quantity > 5
    AND hd.hd_dep_count = 0
    AND p.p_channel_email = 'N'
    AND sr.sr_reversed_charge > 100.00
    AND ws.ws_net_profit < 0
    AND we.web_rec_start_date >= DATE '2000-01-01'
GROUP BY
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    p.p_promo_id,
    we.web_name
LIMIT 100
