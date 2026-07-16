WITH promo_agg AS (
    SELECT
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        d_start.d_year AS start_year,
        d_start.d_fy_quarter_seq AS start_fy_quarter,
        d_end.d_year AS end_year,
        d_end.d_fy_quarter_seq AS end_fy_quarter,
        DATE_DIFF('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
        SUM(p.p_cost) AS total_cost
    FROM promotion p
    JOIN date_dim d_start
      ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
      ON p.p_end_date_sk = d_end.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d_start.d_current_quarter = 'Y'
      AND DATE_DIFF('day', d_start.d_date, d_end.d_date) > 30
    GROUP BY
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        d_start.d_year,
        d_start.d_fy_quarter_seq,
        d_end.d_year,
        d_end.d_fy_quarter_seq,
        d_start.d_date,
        d_end.d_date
    HAVING SUM(p.p_cost) > 1000
)
SELECT
    p.*,
    RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
FROM promo_agg p
ORDER BY cost_rank
LIMIT 50
