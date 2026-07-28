SELECT
  p.p_promo_name,
  s.s_state,
  d_ss.d_year,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(wr.wr_net_loss) AS total_web_returns_loss,
  AVG(ss.ss_ext_tax) AS avg_store_tax,
  MIN(ib.ib_lower_bound) AS min_income,
  MAX(ib.ib_upper_bound) AS max_income
FROM store_sales ss
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
-- Catalog sales and its related dimensions
JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
-- Catalog returns
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
-- Web returns and its related dimensions
JOIN web_returns wr ON d_ss.d_date_sk = wr.wr_returned_date_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
-- Web site (joined via its open date)
JOIN web_site ws ON ws.web_open_date_sk = d_ss.d_date_sk
WHERE d_ss.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND wr.wr_fee > 80
GROUP BY p.p_promo_name, s.s_state, d_ss.d_year
ORDER BY total_store_sales DESC
LIMIT 100
