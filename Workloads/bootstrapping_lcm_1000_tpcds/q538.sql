SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    w_open.web_site_id AS open_site_id,
    w_open.web_name AS open_site_name,
    w_open.web_city AS open_site_city,
    w_close.web_site_id AS close_site_id,
    w_close.web_name AS close_site_name,
    w_close.web_city AS close_site_city,
    p_start.p_promo_id,
    p_start.p_promo_name,
    p_start.p_cost AS start_cost,
    p_end.p_promo_id AS end_promo_id,
    p_end.p_cost AS end_cost,
    (p_end.p_cost - p_start.p_cost) AS cost_diff,
    ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY p_start.p_cost DESC) AS promo_rank,
    COUNT(*) OVER (PARTITION BY d.d_date) AS promotions_per_date
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p_start
    ON p_start.p_start_date_sk = d.d_date_sk
LEFT JOIN promotion p_end
    ON p_end.p_end_date_sk = d.d_date_sk
JOIN web_site w_open
    ON w_open.web_open_date_sk = d.d_date_sk
LEFT JOIN web_site w_close
    ON w_close.web_close_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND w_open.web_state = 'CA'
ORDER BY d.d_date DESC, promo_rank
LIMIT 100
