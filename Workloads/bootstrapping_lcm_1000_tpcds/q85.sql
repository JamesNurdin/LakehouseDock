SELECT
  s.s_store_name,
  d_store_closed.d_year AS store_closed_year,
  d_sold.d_year AS sale_year,
  d_ship.d_month_seq AS ship_month_seq,
  p.p_promo_name,
  DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
  CASE
    WHEN d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date THEN 'Active'
    ELSE 'Inactive'
  END AS promo_status,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS profit_to_payment_ratio,
  AVG(cs.cs_quantity) AS avg_quantity,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  MAX(cs.cs_quantity) AS max_quantity
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_store_closed
  ON cs.cs_sold_date_sk = d_store_closed.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
  s.s_store_name,
  d_store_closed.d_year,
  d_sold.d_year,
  d_ship.d_month_seq,
  p.p_promo_name,
  d_promo_start.d_date,
  d_promo_end.d_date,
  d_sold.d_date
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_ext_sales_price DESC
LIMIT 100
