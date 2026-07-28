WITH avg_net_profit AS (
    SELECT AVG(ws_net_profit) AS avg_profit
    FROM web_sales
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type AS ship_mode_type,
    t_sold.t_sub_shift AS sale_shift
FROM web_sales ws
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = ws.ws_order_number
LEFT JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN store_returns sr
  ON sr.sr_customer_sk = c_bill.c_customer_sk
     AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    t_sold.t_sub_shift
HAVING
    SUM(ws.ws_net_profit) > 100000
    AND AVG(ws.ws_net_profit) > (SELECT avg_profit FROM avg_net_profit)
ORDER BY total_net_profit DESC
LIMIT 100
