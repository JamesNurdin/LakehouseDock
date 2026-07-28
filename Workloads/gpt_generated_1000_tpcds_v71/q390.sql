SELECT
   cp.cp_department,
   d_sold.d_year,
   t_sold.t_hour,
   SUM(cs.cs_net_paid_inc_tax) AS total_sales,
   SUM(sr.sr_return_amt) AS total_store_returns,
   SUM(wr.wr_return_amt) AS total_web_returns,
   COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
   AVG(cs.cs_ext_discount_amt) AS avg_discount
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
WHERE d_sold.d_year = 2001
  AND t_sold.t_hour BETWEEN 9 AND 17
  AND cp.cp_catalog_number IN (4, 7, 11)
  AND sr.sr_return_tax > 10
  AND wr.wr_return_amt < 500
  AND cs.cs_ext_discount_amt > 100
GROUP BY ROLLUP (cp.cp_department, d_sold.d_year, t_sold.t_hour)
ORDER BY total_sales DESC
LIMIT 100
