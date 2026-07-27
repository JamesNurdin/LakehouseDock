WITH promo_agg AS (
    SELECT
        p_start_date_sk,
        COUNT(*) AS promo_cnt,
        SUM(p_cost) AS total_cost,
        AVG(p_cost) AS avg_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_channel_email = 'Y'
      AND p_channel_press = 'N'
      AND p_cost > 0
    GROUP BY p_start_date_sk
)
SELECT
    s.s_state,
    s.s_city,
    d_start.d_year,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(pa.total_cost) AS sum_total_cost,
    AVG(s.s_floor_space) AS avg_floor_space,
    MIN(d_start.d_date) AS min_start_date,
    MAX(d_end.d_date) AS max_end_date
FROM store s
JOIN date_dim d_end
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN promotion p
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN promo_agg pa
    ON pa.p_start_date_sk = d_start.d_date_sk
WHERE s.s_state = 'CA'
  AND s.s_market_manager = 'John Sizemore'
  AND s.s_gmt_offset BETWEEN -5.00 AND -4.00
  AND d_start.d_year = 2001
  AND d_start.d_holiday = 'N'
  AND d_end.d_following_holiday = 'N'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = p.p_item_sk
          AND p2.p_cost > 5000
      )
GROUP BY s.s_state, s.s_city, d_start.d_year
HAVING SUM(pa.total_cost) > 10000
ORDER BY sum_total_cost DESC
LIMIT 100
