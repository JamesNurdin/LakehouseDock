SELECT
    d.d_year AS year,
    s.s_state AS state,
    sm.sm_type AS ship_mode_type,
    r_cr.r_reason_desc AS reason_desc,
    hd_returning.hd_buy_potential AS household_buy_potential,
    wp.wp_type AS web_page_type,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT c_returning.c_customer_sk) AS unique_customers,
    AVG(wr.wr_fee) AS avg_web_return_fee
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN customer c_wp
    ON wp.wp_customer_sk = c_wp.c_customer_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_customer_sk = c_returning.c_customer_sk
   AND sr.sr_hdemo_sk = hd_returning.hd_demo_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
   AND wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
   AND wr.wr_returning_customer_sk = c_returning.c_customer_sk
   AND wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE d.d_qoy = 3
  AND d.d_month_seq >= 1200
  AND c_returning.c_preferred_cust_flag = 'Y'
  AND sm.sm_type = 'AIR'
  AND s.s_state = 'CA'
  AND wr.wr_fee > 50.00
  AND inv.inv_quantity_on_hand > 0
  AND ws.web_country = 'United States'
GROUP BY d.d_year,
         s.s_state,
         sm.sm_type,
         r_cr.r_reason_desc,
         hd_returning.hd_buy_potential,
         wp.wp_type
HAVING SUM(cr.cr_return_amount) > 10000
   AND SUM(inv.inv_quantity_on_hand) > 500
ORDER BY SUM(cr.cr_return_amount) DESC
LIMIT 100
