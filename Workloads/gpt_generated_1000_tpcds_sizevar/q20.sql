WITH sub1 AS (
   SELECT
       ib.ib_income_band_sk,
       CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_range,
       COUNT(hd.hd_demo_sk) AS household_cnt,
       AVG(hd.hd_vehicle_count) AS avg_vehicles,
       (SELECT COUNT(*) FROM tpcds.household_demographics) AS total_households
   FROM tpcds.household_demographics hd
   RIGHT OUTER JOIN tpcds.income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE hd.hd_vehicle_count >= 2
     AND hd.hd_dep_count <= 5
   GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
sub2 AS (
   SELECT
       ib.ib_income_band_sk,
       CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_range,
       COUNT(hd.hd_demo_sk) AS household_cnt,
       AVG(hd.hd_vehicle_count) AS avg_vehicles,
       (SELECT COUNT(*) FROM tpcds.household_demographics) AS total_households
   FROM tpcds.household_demographics hd
   RIGHT OUTER JOIN tpcds.income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE (hd.hd_vehicle_count <= 0 OR hd.hd_vehicle_count IS NULL)
     AND hd.hd_dep_count > 5
   GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT *
FROM sub1
UNION ALL
SELECT *
FROM sub2
ORDER BY income_range
LIMIT 100
