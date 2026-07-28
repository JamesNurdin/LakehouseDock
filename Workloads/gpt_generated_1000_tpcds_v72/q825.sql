SELECT
  d_sold.d_year,
  d_sold.d_month_seq,
  s.s_store_name,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
  SUM(cr.cr_return_amount) AS total_returns,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(wr.wr_return_amt) AS total_web_returns,
  (SUM(cs.cs_net_profit) - SUM(cr.cr_fee) - SUM(wr.wr_fee)) AS net_profit_estimate
FROM
  catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
  ON cr.cr_returned_time_sk = t_return.t_time_sk
LEFT JOIN catalog_page cp_ret
  ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN warehouse w_ret
  ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
LEFT JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
  AND ss.ss_item_sk = i.i_item_sk
  AND ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN time_dim t_store
  ON ss.ss_sold_time_sk = t_store.t_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_sold.d_date_sk
  AND wr.wr_item_sk = i.i_item_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_web
  ON wr.wr_returned_date_sk = d_web.d_date_sk
LEFT JOIN time_dim t_web
  ON wr.wr_returned_time_sk = t_web.t_time_sk
WHERE
  d_sold.d_year = 2001
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
  GROUPING SETS (
    (d_sold.d_year, d_sold.d_month_seq, s.s_store_name),
    (d_sold.d_year, d_sold.d_month_seq),
    (d_sold.d_year),
    ()
  )
ORDER BY
  d_sold.d_year DESC,
  d_sold.d_month_seq,
  s.s_store_name
LIMIT 100
