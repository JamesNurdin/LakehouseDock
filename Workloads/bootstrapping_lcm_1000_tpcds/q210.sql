WITH promo_periods AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_discount_active,
        ds.d_date AS start_date,
        ds.d_year AS start_year,
        ds.d_month_seq AS start_month_seq,
        de.d_date AS end_date,
        de.d_year AS end_year,
        de.d_month_seq AS end_month_seq,
        s.s_store_name,
        s.s_state,
        s.s_number_employees,
        s.s_tax_percentage
    FROM promotion p
    JOIN date_dim ds ON p.p_start_date_sk = ds.d_date_sk
    JOIN date_dim de ON p.p_end_date_sk = de.d_date_sk
    JOIN store s ON s.s_closed_date_sk = ds.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND s.s_state IN ('CA', 'NY', 'TX')
      AND ds.d_year BETWEEN 2020 AND 2023
)
SELECT
    start_year,
    end_year,
    start_month_seq,
    end_month_seq,
    p_promo_name,
    s_store_name,
    s_state,
    s_number_employees,
    p_cost,
    p_cost * (1 - COALESCE(s_tax_percentage, 0)) AS net_cost,
    CASE
        WHEN end_date < CURRENT_DATE THEN 'Ended'
        WHEN start_date > CURRENT_DATE THEN 'Upcoming'
        ELSE 'Active'
    END AS promo_status,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY p_cost DESC) AS rank_by_cost
FROM promo_periods
WHERE p_cost * (1 - COALESCE(s_tax_percentage, 0)) > 0
ORDER BY s_state, rank_by_cost
LIMIT 100
