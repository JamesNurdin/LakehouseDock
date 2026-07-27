WITH
  sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_promo_sk,
      ss.ss_net_paid,
      ss.ss_ext_discount_amt,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    WHERE d_sales.d_year = 2001
  ),
  store_ret AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE d_sr.d_year = 2001
  ),
  catalog_ret AS (
    SELECT
      cr.cr_return_amount,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    WHERE d_cr.d_year = 2001
  ),
  web_ret AS (
    SELECT
      wr.wr_return_amt,
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_web_page_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_refunded_hdemo_sk
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE d_wr.d_year = 2001
  ),
  promo AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_id,
      p.p_channel_email,
      p.p_channel_event,
      p.p_start_date_sk,
      p.p_end_date_sk
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE p.p_channel_email = 'N'
      AND p.p_channel_event = 'Y'
  ),
  call_ctr AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      cc.cc_closed_date_sk
    FROM call_center cc
    JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
    WHERE d_cc.d_year = 2001
  ),
  catalog_pg AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      cp.cp_type,
      cp.cp_start_date_sk
    FROM catalog_page cp
    JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
    WHERE d_cp.d_year = 2001
  ),
  web_pg AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_type,
      wp.wp_creation_date_sk
    FROM web_page wp
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    WHERE d_wp.d_year = 2001
  ),
  cust AS (
    SELECT
      c.c_customer_sk,
      c.c_salutation,
      c.c_current_hdemo_sk,
      c.c_first_shipto_date_sk
    FROM customer c
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    WHERE d_ship.d_year = 2001
  ),
  hdemo AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential
    FROM household_demographics hd
    WHERE hd.hd_income_band_sk = 5
  )
SELECT
  p.p_promo_id,
  cc.cc_name,
  cp.cp_department,
  wp.wp_type,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
  SUM(s.ss_net_paid)                     AS total_sales_net_paid,
  SUM(s.ss_ext_discount_amt)             AS total_discount_amount,
  SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
  AVG(s.ss_ext_discount_amt)             AS avg_discount_per_sale,
  MIN(s.ss_net_paid)                     AS min_sale_net,
  MAX(s.ss_net_paid)                     AS max_sale_net
FROM sales s
JOIN promo p      ON s.ss_promo_sk = p.p_promo_sk
JOIN cust c        ON s.ss_customer_sk = c.c_customer_sk
JOIN hdemo hd      ON s.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_ret sr   ON s.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN catalog_ret cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN web_ret wr      ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN call_ctr cc     ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_pg cp    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_pg wp        ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.c_salutation = 'Mr.'
GROUP BY
  p.p_promo_id,
  cc.cc_name,
  cp.cp_department,
  wp.wp_type
ORDER BY total_sales_net_paid DESC
LIMIT 100
