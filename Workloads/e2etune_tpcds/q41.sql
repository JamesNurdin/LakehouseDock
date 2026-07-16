WITH hd_income AS (
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd.hd_dep_count) AS total_dep_cnt,
        SUM(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_potential_cnt
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 50000
      AND ib.ib_lower_bound <= 100000
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING COUNT(*) >= 100
)
SELECT
    hi.hd_income_band_sk,
    hi.ib_lower_bound,
    hi.ib_upper_bound,
    hi.household_cnt,
    hi.avg_vehicle_cnt,
    hi.total_dep_cnt,
    CAST(hi.high_potential_cnt AS DOUBLE) / hi.household_cnt AS high_potential_ratio,
    (SELECT AVG(p.p_cost)
     FROM promotion p
     WHERE p.p_discount_active = 'Y'
       AND p.p_start_date_sk >= 2451545) AS avg_active_promo_cost,
    (SELECT COUNT(*)
     FROM call_center cc
     WHERE cc.cc_state = 'CA'
       AND cc.cc_mkt_id IN (2, 3)) AS ca_call_center_cnt,
    (SELECT COUNT(DISTINCT sm_type)
     FROM ship_mode) AS distinct_ship_mode_types
FROM hd_income hi
ORDER BY high_potential_ratio DESC
LIMIT 50
