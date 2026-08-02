SELECT
    hd.hd_income_band_sk AS income_band_sk,
    concat('Band ', CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_band_range,
    COUNT(*) AS total_households,
    AVG(hd.hd_dep_count) AS avg_dependents,
    AVG(hd.hd_vehicle_count) AS avg_vehicles,
    SUM(CASE WHEN regexp_like(hd.hd_buy_potential, '^H.*') THEN 1 ELSE 0 END) AS high_potential_cnt,
    SUM(CASE WHEN regexp_extract(hd.hd_buy_potential, '^([A-Za-z]+)', 1) = 'High' THEN 1 ELSE 0 END) AS high_extracted_cnt,
    SUM(CASE WHEN hd.hd_buy_potential LIKE '%Low%' THEN 1 ELSE 0 END) AS low_potential_cnt,
    array_agg(DISTINCT substring(hd.hd_buy_potential, 1, 3)) AS buy_potential_prefixes,
    (SELECT COUNT(*)
       FROM household_demographics hd_sub
      WHERE hd_sub.hd_income_band_sk = hd.hd_income_band_sk
        AND hd_sub.hd_dep_count > 2) AS households_dep_gt_2
FROM household_demographics hd
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE regexp_like(hd.hd_buy_potential, '^(Low|Medium|High)')
GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_households DESC
