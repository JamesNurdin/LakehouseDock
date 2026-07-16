SELECT
    cc.cc_state,
    cc.cc_city,
    cc.cc_zip,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    AVG(cc.cc_sq_ft) AS avg_sq_ft,
    SUM(cc.cc_sq_ft) AS total_sq_ft,
    ca.address_cnt,
    hd.avg_vehicle_count,
    hd.total_households,
    COUNT(DISTINCT td.t_shift) AS distinct_shifts,
    RANK() OVER (ORDER BY AVG(cc.cc_sq_ft) DESC) AS sq_ft_rank
FROM call_center cc
JOIN (
    SELECT
        ca_state,
        ca_city,
        ca_zip,
        COUNT(*) AS address_cnt
    FROM customer_address
    WHERE ca_country = 'United States'
    GROUP BY ca_state, ca_city, ca_zip
) ca
    ON cc.cc_state = ca.ca_state
    AND cc.cc_city = ca.ca_city
    AND cc.cc_zip = ca.ca_zip
JOIN (
    SELECT
        mod(hd_income_band_sk, 5) AS join_key,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        COUNT(*) AS total_households
    FROM household_demographics
    WHERE hd_vehicle_count > 0
    GROUP BY mod(hd_income_band_sk, 5)
) hd
    ON mod(cc.cc_sq_ft, 5) = hd.join_key
JOIN time_dim td
    ON mod(cc.cc_sq_ft, 24) = td.t_hour
WHERE cc.cc_tax_percentage > 0.05
  AND cc.cc_division_name IN ('pri', 'anti', 'ought')
GROUP BY
    cc.cc_state,
    cc.cc_city,
    cc.cc_zip,
    ca.address_cnt,
    hd.avg_vehicle_count,
    hd.total_households
HAVING COUNT(DISTINCT cc.cc_call_center_id) >= 2
ORDER BY total_sq_ft DESC
LIMIT 100
