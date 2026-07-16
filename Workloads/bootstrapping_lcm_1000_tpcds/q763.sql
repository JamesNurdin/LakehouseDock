SELECT
  s.s_store_id,
  s.s_city,
  d_sold.d_year,
  d_sold.d_month_seq,
  CASE
    WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
    WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
    WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
  END AS time_of_day,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  AVG(cs.cs_ext_sales_price) AS avg_sales_price,
  SUM(cs.cs_ext_sales_price) / NULLIF(SUM(cs.cs_ext_list_price), 0) AS sales_to_list_ratio,
  SUM(cs.cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT p.p_promo_id) AS num_promotions,
  MAX(p.p_discount_active) AS discount_active_flag,
  SUM(CASE WHEN p.p_channel_tv = 'Y' THEN 1 ELSE 0 END) AS tv_promo_count,
  SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS email_promo_count
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year = 2020
  AND d_ship.d_year = 2020
  AND d_promo_start.d_year <= 2020
  AND d_promo_end.d_year >= 2020
GROUP BY
  s.s_store_id,
  s.s_city,
  d_sold.d_year,
  d_sold.d_month_seq,
  CASE
    WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
    WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
    WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
  END
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
