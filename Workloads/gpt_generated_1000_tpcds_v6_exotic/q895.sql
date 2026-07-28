WITH promo_costs AS (
    SELECT
        p.p_promo_id,
        d_start.d_year AS start_year,
        d_end.d_year AS end_year,
        d_start.d_quarter_name AS start_quarter,
        d_end.d_quarter_name AS end_quarter,
        SUM(p.p_cost) AS total_cost,
        COUNT(*) AS promo_count
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_current_day = 'N'
      AND d_end.d_following_holiday = 'N'
      AND p.p_channel_event = 'N'
      AND p.p_channel_press = 'N'
      AND p.p_channel_catalog = 'N'
      AND d_start.d_same_day_lq = 2414934
    GROUP BY
        p.p_promo_id,
        d_start.d_year,
        d_end.d_year,
        d_start.d_quarter_name,
        d_end.d_quarter_name
)
SELECT
    pc.start_year,
    pc.start_quarter,
    AVG(pc.total_cost) AS avg_total_cost,
    SUM(pc.promo_count) AS total_promos
FROM promo_costs pc
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_id = pc.p_promo_id
      AND p2.p_cost > 10000
)
GROUP BY pc.start_year, pc.start_quarter
HAVING AVG(pc.total_cost) > 5000
ORDER BY pc.start_year DESC, pc.start_quarter
LIMIT 100
