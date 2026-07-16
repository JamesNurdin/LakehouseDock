SELECT
  d_sales.d_year AS sale_year,
  d_sales.d_month_seq AS sale_month,
  i.i_category,
  i.i_brand,
  s.s_store_name,
  s.s_city,
  s.s_state,
  p.p_promo_name,
  p.p_discount_active,
  d_start.d_date AS promo_start_date,
  d_end.d_date AS promo_end_date,
  d_closed.d_date AS store_closed_date,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_ext_discount_amt) AS total_discount,
  SUM(ss.ss_net_profit) AS total_profit,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  AVG(ss.ss_sales_price) AS avg_sales_price,
  SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
  AND p.p_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND (d_closed.d_date IS NULL OR d_closed.d_date > CURRENT_DATE)
GROUP BY
  d_sales.d_year,
  d_sales.d_month_seq,
  i.i_category,
  i.i_brand,
  s.s_store_name,
  s.s_city,
  s.s_state,
  p.p_promo_name,
  p.p_discount_active,
  d_start.d_date,
  d_end.d_date,
  d_closed.d_date
ORDER BY total_sales DESC
LIMIT 100
