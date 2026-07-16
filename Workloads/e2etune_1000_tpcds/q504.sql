WITH promo_agg AS (
    SELECT
        start_d.d_year AS start_year,
        start_d.d_quarter_name AS start_quarter,
        CASE
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_radio = 'Y' THEN 'Radio'
            WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
            WHEN p.p_channel_dmail = 'Y' THEN 'Direct Mail'
            WHEN p.p_channel_press = 'Y' THEN 'Press'
            ELSE 'Other'
        END AS promo_channel,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        SUM(p.p_cost) AS total_cost,
        AVG(p.p_cost) AS avg_cost
    FROM promotion p
    JOIN date_dim start_d ON p.p_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON p.p_end_date_sk = end_d.d_date_sk
    WHERE start_d.d_year = 2023
      AND end_d.d_year = 2023
      AND p.p_discount_active = 'Y'
      AND start_d.d_current_quarter = 'Y'
    GROUP BY start_d.d_year,
             start_d.d_quarter_name,
             CASE
                WHEN p.p_channel_tv = 'Y' THEN 'TV'
                WHEN p.p_channel_email = 'Y' THEN 'Email'
                WHEN p.p_channel_radio = 'Y' THEN 'Radio'
                WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
                WHEN p.p_channel_dmail = 'Y' THEN 'Direct Mail'
                WHEN p.p_channel_press = 'Y' THEN 'Press'
                ELSE 'Other'
             END
    HAVING COUNT(DISTINCT p.p_promo_id) >= 5
)
SELECT
    start_year,
    start_quarter,
    promo_channel,
    promo_count,
    total_cost,
    avg_cost,
    RANK() OVER (PARTITION BY start_year ORDER BY total_cost DESC) AS cost_rank
FROM promo_agg
ORDER BY start_year, start_quarter, cost_rank
