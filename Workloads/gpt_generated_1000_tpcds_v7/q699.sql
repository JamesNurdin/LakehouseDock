SELECT
  w.w_country AS warehouse_country,
  p.p_channel_email,
  d_sold.d_year,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(wr.wr_return_amt) AS total_return_amount
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY GROUPING SETS (
  (w.w_country, p.p_channel_email, d_sold.d_year),
  (w.w_country, p.p_channel_email),
  (w.w_country),
  ()
)
ORDER BY warehouse_country, p_channel_email, d_year
