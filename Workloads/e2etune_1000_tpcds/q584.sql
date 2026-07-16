WITH market_stats AS (
    SELECT
        s_market_id,
        s_state,
        COUNT(*) AS store_count,
        SUM(s_floor_space) AS total_floor_space,
        AVG(s_tax_percentage) AS avg_tax_pct,
        MIN(s_rec_start_date) AS earliest_open,
        MAX(COALESCE(s_rec_end_date, DATE '9999-12-31')) AS latest_close
    FROM store
    WHERE s_rec_start_date >= DATE '1999-01-01'
      AND s_state IN ('CA', 'TX', 'NY')
    GROUP BY s_market_id, s_state
),
ranked_markets AS (
    SELECT
        s_market_id,
        s_state,
        store_count,
        total_floor_space,
        avg_tax_pct,
        earliest_open,
        latest_close,
        RANK() OVER (ORDER BY total_floor_space DESC) AS floor_space_rank
    FROM market_stats
)
SELECT
    r.s_market_id,
    r.s_state,
    r.store_count,
    r.total_floor_space,
    r.avg_tax_pct,
    r.floor_space_rank,
    t.t_hour,
    t.t_shift,
    t.t_meal_time,
    COUNT(*) OVER (PARTITION BY r.s_market_id) AS stores_per_market_ranked
FROM ranked_markets r
JOIN time_dim t
  ON t.t_hour = MOD(DAY(r.earliest_open), 24)
WHERE t.t_shift IS NOT NULL
ORDER BY r.floor_space_rank ASC, r.total_floor_space DESC
LIMIT 100
