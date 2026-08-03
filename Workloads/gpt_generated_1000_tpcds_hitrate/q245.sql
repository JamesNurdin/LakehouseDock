WITH sampled_hd AS (
   SELECT hd_demo_sk,
          hd_income_band_sk,
          hd_buy_potential,
          hd_vehicle_count,
          hd_dep_count
   FROM tpcds.household_demographics
   TABLESAMPLE BERNOULLI (10)
   WHERE hd_buy_potential NOT IN ('Unknown')
     AND hd_vehicle_count >= 0
     AND hd_dep_count <= 5
),
joined AS (
   SELECT hd.hd_demo_sk,
          hd.hd_income_band_sk,
          hd.hd_buy_potential,
          hd.hd_vehicle_count,
          hd.hd_dep_count,
          ib.ib_income_band_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound
   FROM sampled_hd AS hd
   FULL OUTER JOIN tpcds.income_band AS ib
          ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE (ib.ib_upper_bound IS NULL OR ib.ib_upper_bound <= 150000)
     AND (hd.hd_vehicle_count IS NULL OR hd.hd_vehicle_count <> -1)
),
band_desc AS (
   SELECT j.*, bw.band_category
   FROM joined AS j
   LEFT JOIN LATERAL (
       SELECT CASE
                WHEN j.ib_upper_bound IS NOT NULL AND j.ib_lower_bound IS NOT NULL
                     AND (j.ib_upper_bound - j.ib_lower_bound) > 50000 THEN 'Wide'
                WHEN j.ib_upper_bound IS NOT NULL AND j.ib_lower_bound IS NOT NULL THEN 'Narrow'
                ELSE 'Unknown'
              END AS band_category
   ) AS bw ON TRUE
)
SELECT
   bd.ib_income_band_sk,
   bd.ib_lower_bound,
   bd.ib_upper_bound,
   bd.band_category,
   COUNT(DISTINCT bd.hd_vehicle_count) OVER (PARTITION BY bd.ib_income_band_sk) AS distinct_vehicle_count_per_band,
   COUNT(DISTINCT bd.hd_buy_potential) OVER (PARTITION BY bd.ib_income_band_sk) AS distinct_buy_potential_per_band,
   RANK() OVER (PARTITION BY bd.ib_income_band_sk ORDER BY bd.hd_vehicle_count DESC NULLS LAST) AS vehicle_count_rank
FROM band_desc AS bd
WHERE bd.hd_buy_potential IS NOT NULL
ORDER BY bd.ib_income_band_sk, vehicle_count_rank
LIMIT 100
