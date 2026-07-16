SELECT
    d_start.d_year,
    d_start.d_current_month,
    s.s_city,
    s.s_state,
    i.i_category,
    CASE
        WHEN DATE_DIFF('day', d_start.d_date, d_end.d_date) > 30 THEN 'Long'
        ELSE 'Short'
    END AS promo_length_category,
    COUNT(*) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(p.p_cost) AS max_promo_cost
FROM store s
JOIN date_dim d_start
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN item i
    ON p.p_item_sk = i.i_item_sk
WHERE d_start.d_year = 2022
GROUP BY
    d_start.d_year,
    d_start.d_current_month,
    s.s_city,
    s.s_state,
    i.i_category,
    CASE
        WHEN DATE_DIFF('day', d_start.d_date, d_end.d_date) > 30 THEN 'Long'
        ELSE 'Short'
    END
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
