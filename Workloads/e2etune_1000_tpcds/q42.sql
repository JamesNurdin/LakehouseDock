SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
    SUM(hd.hd_vehicle_count) AS total_vehicles,
    (SELECT AVG(p.p_cost) FROM promotion p WHERE p.p_discount_active = 'Y' AND p.p_start_date_sk BETWEEN 20000101 AND 20001231) AS avg_active_promo_cost,
    (SELECT COUNT(*) FROM ship_mode sm WHERE sm.sm_type = 'AIR') AS total_air_ship_modes,
    (SELECT AVG(cc.cc_sq_ft) FROM call_center cc WHERE cc.cc_state = 'CA' AND cc.cc_rec_end_date > DATE '2000-12-31') AS avg_sqft_ca_call_center
FROM household_demographics hd
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count >= 2
  AND ib.ib_lower_bound >= 30000
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
HAVING COUNT(DISTINCT hd.hd_demo_sk) > 5
ORDER BY total_vehicles DESC
LIMIT 100
