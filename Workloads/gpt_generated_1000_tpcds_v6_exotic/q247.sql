SELECT
  d_cs_sold.d_year,
  i.i_category,
  hd.hd_buy_potential,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  SUM(cs.cs_ext_sales_price)            AS catalog_sales_amount,
  SUM(ss.ss_ext_sales_price)            AS store_sales_amount,
  SUM(sr.sr_return_amt)                 AS store_returns_amount,
  SUM(wr.wr_return_amt)                 AS web_returns_amount
FROM catalog_sales cs
JOIN date_dim d_cs_sold
  ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs_sold
  ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_ss_sold
  ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
JOIN time_dim t_ss_sold
  ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk      = ss.ss_item_sk
JOIN date_dim d_sr_returned
  ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
JOIN time_dim t_sr_returned
  ON sr.sr_return_time_sk = t_sr_returned.t_time_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr_returned
  ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
JOIN time_dim t_wr_returned
  ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_cs_sold.d_year = 2001
  AND i.i_color = 'sienna'
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY d_cs_sold.d_year, i.i_category, hd.hd_buy_potential
HAVING SUM(cs.cs_ext_sales_price) > 100000
ORDER BY d_cs_sold.d_year, i.i_category
LIMIT 100
