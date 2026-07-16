WITH promo_stats AS (
    SELECT
        ca.ca_county,
        sm.sm_type,
        COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
        AVG(p.p_cost) AS avg_cost,
        SUM(ib.ib_upper_bound - ib.ib_lower_bound) AS income_range_sum
    FROM promotion p
    JOIN income_band ib ON p.p_response_target = ib.ib_income_band_sk
    JOIN ship_mode sm ON p.p_promo_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ca.ca_address_sk = p.p_item_sk
    WHERE ca.ca_state = 'AZ'
      AND sm.sm_carrier LIKE 'UPS%'
      AND p.p_discount_active = 'Y'
    GROUP BY ca.ca_county, sm.sm_type
    HAVING COUNT(DISTINCT p.p_promo_sk) > 5
)
SELECT
    ca_county,
    sm_type,
    promo_cnt,
    avg_cost,
    income_range_sum,
    RANK() OVER (PARTITION BY ca_county ORDER BY avg_cost DESC) AS cost_rank
FROM promo_stats
ORDER BY promo_cnt DESC, avg_cost ASC
LIMIT 50
