SELECT
  p.p_promo_id,
  p.p_promo_name,
  d_promo_start.d_year AS promo_start_year,
  d_promo_end.d_year   AS promo_end_year,
  s.s_store_id,
  s.s_store_name,
  ws.web_site_id,
  ws.web_name,
  d_sold.d_year        AS sold_year,
  d_sold.d_month_seq   AS sold_month,
  SUM(cs.cs_net_paid)      AS total_net_paid,
  SUM(cs.cs_net_profit)    AS total_net_profit,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders
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
CROSS JOIN store s
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim d_web_open
  ON ws.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close
  ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE cs.cs_quantity > 0
  AND d_sold.d_year = 2022
  AND d_ship.d_year = 2022
  AND d_store_closed.d_year = 2022
  AND d_web_open.d_year <= 2022
  AND d_web_close.d_year >= 2022
GROUP BY
  p.p_promo_id,
  p.p_promo_name,
  d_promo_start.d_year,
  d_promo_end.d_year,
  s.s_store_id,
  s.s_store_name,
  ws.web_site_id,
  ws.web_name,
  d_sold.d_year,
  d_sold.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
