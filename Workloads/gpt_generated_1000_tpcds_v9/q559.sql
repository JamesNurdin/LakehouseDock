WITH promo_agg AS (
    SELECT
        p_start_date_sk,
        COUNT(*) AS promo_cnt,
        SUM(p_cost) AS total_cost,
        AVG(p_cost) AS avg_cost
    FROM promotion
    WHERE
        p_channel_press = 'N'
        AND p_purpose = 'Unknown'
        AND p_promo_id IN (
            'AAAAAAAAEBAAAAAA',
            'AAAAAAAAIAAAAAAA',
            'AAAAAAAAAPAAAAAAA',
            'AAAAAAAAJAAAAAAA',
            'AAAAAAAAEAAAAAAA'
        )
        AND p_cost > 10
        AND p_response_target >= 100
    GROUP BY p_start_date_sk
)
SELECT
    d.d_fy_quarter_seq,
    d.d_day_name,
    SUM(pa.total_cost) AS sum_total_cost,
    SUM(pa.promo_cnt) AS total_promotions,
    AVG(pa.avg_cost) AS avg_cost_per_start_date
FROM promo_agg pa
INNER JOIN date_dim d
    ON pa.p_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND d.d_month_seq BETWEEN 60 AND 120
    AND d.d_fy_quarter_seq IN (13, 9, 14, 11, 7)
    AND d.d_day_name = 'Tuesday  '
    AND d.d_holiday = 'N'
GROUP BY d.d_fy_quarter_seq, d.d_day_name
HAVING
    SUM(pa.total_cost) > 10000
    AND SUM(pa.promo_cnt) > 20
ORDER BY d.d_fy_quarter_seq ASC, sum_total_cost DESC
LIMIT 100
