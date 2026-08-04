WITH hd_cte AS (
   SELECT
       hd_demo_sk,
       hd_income_band_sk,
       hd_buy_potential,
       hd_vehicle_count,
       hd_dep_count,
       ARRAY[hd_vehicle_count, hd_dep_count] AS counts_arr
   FROM household_demographics
   WHERE regexp_like(hd_buy_potential, '^\\d{1,4}-\\d{1,4}$')
     AND hd_buy_potential LIKE '%-%'
),
unnested_cte AS (
   SELECT
       hd_demo_sk,
       hd_income_band_sk,
       hd_buy_potential,
       cnt_idx,
       cnt_value
   FROM hd_cte
   CROSS JOIN UNNEST(counts_arr) WITH ORDINALITY AS t(cnt_value, cnt_idx)
),
income_cte AS (
   SELECT
       ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound
   FROM income_band
   WHERE ib_upper_bound > 100000
),
joined_cte AS (
   SELECT
       u.hd_demo_sk,
       u.hd_income_band_sk,
       u.hd_buy_potential,
       u.cnt_idx,
       u.cnt_value,
       i.ib_lower_bound,
       i.ib_upper_bound
   FROM unnested_cte u
   FULL OUTER JOIN income_cte i
        ON u.hd_income_band_sk = i.ib_income_band_sk
),
exclude_keys AS (
   SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count = 0
)
SELECT
    j.hd_buy_potential,
    SUM(j.cnt_value) AS total_metric,
    COUNT(DISTINCT j.hd_demo_sk) AS household_cnt
FROM joined_cte j
WHERE j.hd_demo_sk NOT IN (SELECT hd_demo_sk FROM exclude_keys)
  AND j.hd_demo_sk IN (
        SELECT hd_demo_sk FROM household_demographics
        WHERE hd_buy_potential LIKE '%-%'
        EXCEPT
        SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count = 0
  )
GROUP BY j.hd_buy_potential
ORDER BY total_metric DESC
LIMIT 100
