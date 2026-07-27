WITH start_promos AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_cost AS promo_cost,
        d.d_date AS promo_date,
        d.d_day_name AS day_name,
        'START' AS promo_phase
    FROM promotion p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_demo = 'N'
),
end_promos AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_cost AS promo_cost,
        d.d_date AS promo_date,
        d.d_day_name AS day_name,
        'END' AS promo_phase
    FROM promotion p
    JOIN date_dim d
        ON p.p_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_demo = 'N'
)
SELECT
    promo_id,
    promo_cost,
    promo_date,
    day_name,
    promo_phase
FROM (
    SELECT promo_id, promo_cost, promo_date, day_name, promo_phase FROM start_promos
    UNION ALL
    SELECT promo_id, promo_cost, promo_date, day_name, promo_phase FROM end_promos
) AS combined
ORDER BY promo_date DESC
LIMIT 100
