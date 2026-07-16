SELECT
    d_start.d_current_year AS promo_year,
    s.s_state,
    i.i_brand,
    p.p_purpose,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(p.p_cost) / NULLIF(SUM(s.s_floor_space), 0) AS cost_per_sqft,
    CASE
        WHEN date_diff('day', d_start.d_date, d_end.d_date) <= 30 THEN 'Short'
        WHEN date_diff('day', d_start.d_date, d_end.d_date) <= 90 THEN 'Medium'
        ELSE 'Long'
    END AS duration_bucket,
    COUNT(DISTINCT w_open.web_site_id) AS open_sites,
    COUNT(DISTINCT w_close.web_site_id) AS close_sites
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_site w_open ON w_open.web_open_date_sk = d_start.d_date_sk
JOIN web_site w_close ON w_close.web_close_date_sk = d_end.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND s.s_number_employees > 0
GROUP BY
    d_start.d_current_year,
    s.s_state,
    i.i_brand,
    p.p_purpose,
    CASE
        WHEN date_diff('day', d_start.d_date, d_end.d_date) <= 30 THEN 'Short'
        WHEN date_diff('day', d_start.d_date, d_end.d_date) <= 90 THEN 'Medium'
        ELSE 'Long'
    END
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
