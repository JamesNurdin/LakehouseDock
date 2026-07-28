WITH
  d_sold AS (SELECT * FROM date_dim),
  d_promo_start AS (SELECT * FROM date_dim),
  d_promo_end AS (SELECT * FROM date_dim),
  d_return AS (SELECT * FROM date_dim),
  d_wp_create AS (SELECT * FROM date_dim),
  d_wp_access AS (SELECT * FROM date_dim),
  d_wr_return AS (SELECT * FROM date_dim)
SELECT
  p.p_promo_name,
  hd_sales.hd_vehicle_count,
  d_sold.d_year,
  SUM(ss.ss_net_paid) AS total_sales,
  SUM(sr.sr_net_loss) AS store_return_loss,
  SUM(wr.wr_net_loss) AS web_return_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
FROM store_sales ss
JOIN d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
JOIN d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN household_demographics hd_return ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
JOIN web_returns wr ON wr.wr_returning_hdemo_sk = hd_sales.hd_demo_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
WHERE p.p_discount_active = 'Y'
GROUP BY p.p_promo_name, hd_sales.hd_vehicle_count, d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
