SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sc.d_date AS store_closed_date,
    p.p_promo_name,
    p.p_discount_active,
    csd.d_date AS promo_start_date,
    d_sc.d_date AS promo_end_date,
    csd.d_year AS promo_start_year,
    csd.d_month_seq AS promo_start_month_seq,
    csd.d_day_name AS promo_start_day_name,
    d_sc.d_year AS promo_end_year,
    d_sc.d_month_seq AS promo_end_month_seq,
    d_sc.d_day_name AS promo_end_day_name,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(DATE_DIFF('day', csd.d_date, d_sc.d_date)) AS avg_days_between_promo_start_and_end,
    SUM(p.p_cost) AS total_promo_cost,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(p.p_cost) AS max_promo_cost
FROM date_dim csd
JOIN customer c
  ON c.c_first_sales_date_sk = csd.d_date_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON p.p_start_date_sk = csd.d_date_sk
JOIN date_dim d_sc
  ON p.p_end_date_sk = d_sc.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sc.d_date_sk
WHERE ca.ca_country = 'United States'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sc.d_date,
    p.p_promo_name,
    p.p_discount_active,
    csd.d_date,
    csd.d_year,
    csd.d_month_seq,
    csd.d_day_name,
    d_sc.d_year,
    d_sc.d_month_seq,
    d_sc.d_day_name,
    ca.ca_city,
    ca.ca_state
ORDER BY num_customers DESC
LIMIT 100
