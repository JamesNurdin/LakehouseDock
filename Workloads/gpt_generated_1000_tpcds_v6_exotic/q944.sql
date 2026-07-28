SELECT
  d.d_year,
  s.s_store_name,
  c.c_customer_id,
  cd.cd_gender,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return,
  SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return,
  (SUM(ss.ss_ext_sales_price) -
   SUM(COALESCE(sr.sr_return_amt, 0)) -
   SUM(COALESCE(cr.cr_return_amount, 0)) -
   SUM(COALESCE(wr.wr_return_amt, 0))) AS net_revenue,
  RANK() OVER (PARTITION BY d.d_year ORDER BY (SUM(ss.ss_ext_sales_price) -
   SUM(COALESCE(sr.sr_return_amt, 0)) -
   SUM(COALESCE(cr.cr_return_amount, 0)) -
   SUM(COALESCE(wr.wr_return_amt, 0))) DESC) AS revenue_rank
FROM date_dim d
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND s.s_state = 'TX'
  AND cd.cd_gender = 'M'
  AND c.c_preferred_cust_flag = 'Y'
  AND ss.ss_quantity > 0
  AND ss.ss_net_profit > 0
  AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
GROUP BY d.d_year, s.s_store_name, c.c_customer_id, cd.cd_gender
ORDER BY net_revenue DESC, revenue_rank
LIMIT 100
