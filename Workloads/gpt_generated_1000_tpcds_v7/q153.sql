WITH started AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d.d_year AS year,
        d.d_quarter_name AS quarter_name,
        p.p_cost,
        'START' AS period_type
    FROM promotion p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_qoy = 1
      AND p.p_channel_tv = 'N'
),
ended AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d.d_year AS year,
        d.d_quarter_name AS quarter_name,
        p.p_cost,
        'END' AS period_type
    FROM promotion p
    JOIN date_dim d
        ON p.p_end_date_sk = d.d_date_sk
    WHERE d.d_qoy = 4
      AND p.p_channel_demo = 'N'
)
SELECT
    year,
    quarter_name,
    period_type,
    COUNT(DISTINCT p_promo_id) AS promo_count,
    SUM(p_cost) AS total_cost
FROM (
    SELECT * FROM started
    UNION ALL
    SELECT * FROM ended
) u
GROUP BY year, quarter_name, period_type
ORDER BY year DESC, quarter_name, period_type
