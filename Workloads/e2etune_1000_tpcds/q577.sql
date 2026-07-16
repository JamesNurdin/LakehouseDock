WITH promo_details AS (
    SELECT
        p.p_promo_id               AS promo_id,
        p.p_cost                   AS promo_cost,
        p.p_discount_active        AS discount_active,
        i.i_category               AS category,
        i.i_class                  AS class,
        d_start.d_year             AS start_year,
        d_start.d_quarter_name     AS start_quarter,
        d_start.d_date             AS start_date,
        d_end.d_date               AS end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS promo_days
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE d_start.d_year = 2020
      AND p.p_discount_active = 'Y'
)
SELECT
    category,
    start_quarter,
    COUNT(DISTINCT promo_id)                     AS promo_cnt,
    SUM(promo_cost)                              AS total_cost,
    AVG(promo_cost)                              AS avg_cost,
    AVG(promo_days)                              AS avg_duration_days,
    RANK() OVER (ORDER BY SUM(promo_cost) DESC) AS cost_rank
FROM promo_details
GROUP BY category, start_quarter
HAVING SUM(promo_cost) > 10000
ORDER BY total_cost DESC
LIMIT 10
