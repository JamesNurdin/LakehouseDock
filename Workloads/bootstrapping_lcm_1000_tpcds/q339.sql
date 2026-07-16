WITH active_promos AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_channel_email,
        p.p_channel_tv,
        p.p_response_target
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_cost > 0
)
SELECT
    ap.p_promo_id,
    ap.p_promo_name,
    ap.p_cost,
    start_dim.d_date AS promo_start_date,
    end_dim.d_date AS promo_end_date,
    start_dim.d_year AS start_year,
    end_dim.d_year AS end_year,
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    DATE_DIFF('day', start_dim.d_date, end_dim.d_date) AS promo_duration_days,
    CASE
        WHEN start_dim.d_year = end_dim.d_year THEN CAST(start_dim.d_year AS VARCHAR)
        ELSE CONCAT(CAST(start_dim.d_year AS VARCHAR), '-', CAST(end_dim.d_year AS VARCHAR))
    END AS promo_year_range,
    ROW_NUMBER() OVER (PARTITION BY s.s_market_id ORDER BY ap.p_cost DESC) AS promo_rank_by_market,
    SUM(ap.p_cost) OVER (PARTITION BY s.s_market_id) AS total_cost_by_market
FROM active_promos ap
JOIN date_dim start_dim ON ap.p_start_date_sk = start_dim.d_date_sk
JOIN date_dim end_dim ON ap.p_end_date_sk = end_dim.d_date_sk
JOIN store s ON s.s_closed_date_sk = start_dim.d_date_sk
WHERE start_dim.d_month_seq BETWEEN 1 AND 12
  AND s.s_state = 'CA'
ORDER BY s.s_market_id, promo_rank_by_market
LIMIT 100
