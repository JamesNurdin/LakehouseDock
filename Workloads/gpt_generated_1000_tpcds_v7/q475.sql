SELECT
  d.d_year,
  s.s_state,
  i.i_brand,
  SUM(ss.ss_net_paid)                         AS total_sales,
  SUM(sr.sr_return_amt)                       AS total_store_return,
  SUM(cr.cr_return_amount)                    AS total_catalog_return,
  SUM(wr.wr_return_amt)                       AS total_web_return,
  COUNT(DISTINCT c.c_customer_id)             AS distinct_customers,
  AVG(ss.ss_ext_discount_amt)                AS avg_discount_amt,
  MIN(ib.ib_lower_bound)                      AS min_income_lower,
  MAX(ib.ib_upper_bound)                      AS max_income_upper
FROM
  date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  JOIN catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND s.s_state = 'CA'
GROUP BY
  d.d_year,
  s.s_state,
  i.i_brand
