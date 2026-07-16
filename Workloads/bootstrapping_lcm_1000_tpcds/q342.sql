SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sales.d_date AS store_closed_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date AS first_sales_date,
    d_ship.d_date AS first_ship_date,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    p.p_promo_name,
    p.p_cost,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days
FROM date_dim d_sales
JOIN customer c
  ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d_ship
  ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d_sales.d_date_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE p.p_cost > 0
ORDER BY p.p_cost DESC, promo_duration_days DESC
LIMIT 100
