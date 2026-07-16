WITH promo_stats AS (
    SELECT
        p.p_item_sk,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(*) AS promo_count,
        SUM(p.p_cost) AS total_cost,
        AVG(p.p_response_target) AS avg_target
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_item_sk, p.p_start_date_sk, p.p_end_date_sk
)
SELECT
    d_start.d_year,
    d_start.d_month_seq,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    ps.promo_count,
    ps.total_cost,
    ps.avg_target,
    s.s_state,
    s.s_market_desc,
    s.s_floor_space,
    s.s_number_employees,
    CASE WHEN d_start.d_weekend = 'Y' THEN 1 ELSE 0 END AS start_is_weekend,
    CASE WHEN d_end.d_weekend = 'Y' THEN 1 ELSE 0 END AS end_is_weekend
FROM promo_stats ps
JOIN item i ON ps.p_item_sk = i.i_item_sk
JOIN date_dim d_start ON ps.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON ps.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
WHERE ps.total_cost > 5000
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND i.i_category = 'Electronics'
  AND d_start.d_year BETWEEN 2020 AND 2022
ORDER BY ps.total_cost DESC
LIMIT 100
