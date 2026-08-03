WITH base AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ARRAY[hd.hd_vehicle_count, hd.hd_dep_count] AS counts_arr
  FROM tpcds.household_demographics hd
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_buy_potential IN ('1001-5000', '>10000', '0-500')
    AND hd.hd_vehicle_count BETWEEN 0 AND 4
    AND hd.hd_dep_count BETWEEN 0 AND 3
    AND ib.ib_lower_bound >= 10000
    AND ib.ib_upper_bound <= 200000
    AND hd.hd_income_band_sk IS NOT NULL
),
unnested AS (
  SELECT
    b.hd_demo_sk,
    b.hd_income_band_sk,
    b.hd_buy_potential,
    b.ib_lower_bound,
    b.ib_upper_bound,
    v.element AS count_value,
    CASE WHEN v.element > 2 THEN 'high' ELSE 'low' END AS count_category
  FROM base b
  CROSS JOIN UNNEST(b.counts_arr) AS v(element)
),
agg1 AS (
  SELECT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    SUM(count_value) AS total_counts,
    COUNT(DISTINCT hd_demo_sk) AS household_cnt,
    CASE
      WHEN SUM(count_value) > 10 THEN 'large_sum'
      ELSE 'small_sum'
    END AS sum_category
  FROM unnested
  GROUP BY hd_income_band_sk, ib_lower_bound, ib_upper_bound
),
agg2 AS (
  SELECT
    a.hd_income_band_sk,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.total_counts,
    a.household_cnt,
    a.sum_category,
    (SELECT COUNT(*)
       FROM tpcds.household_demographics hd2
       WHERE hd2.hd_income_band_sk = a.hd_income_band_sk
         AND hd2.hd_buy_potential = '5001-10000') AS extra_cnt
  FROM agg1 a
  WHERE a.total_counts >= 5
    AND a.household_cnt BETWEEN 1 AND 100
    AND a.sum_category = 'large_sum'
    AND a.ib_lower_bound < 180000
    AND a.ib_upper_bound > 15000
    AND EXISTS (
      SELECT 1
      FROM tpcds.income_band ib2
      WHERE ib2.ib_income_band_sk = a.hd_income_band_sk
        AND ib2.ib_upper_bound > 120000
    )
)
SELECT
  a.hd_income_band_sk,
  a.ib_lower_bound,
  a.ib_upper_bound,
  a.total_counts,
  a.household_cnt,
  a.sum_category,
  a.extra_cnt,
  CASE WHEN a.extra_cnt > 10 THEN 'many_extra' ELSE 'few_extra' END AS extra_category
FROM agg2 a
WHERE a.hd_income_band_sk IN (
  SELECT hd_income_band_sk FROM agg1 WHERE total_counts > 8
  INTERSECT
  SELECT hd_income_band_sk FROM agg1 WHERE household_cnt < 50
)
ORDER BY a.total_counts DESC, a.hd_income_band_sk
LIMIT 100
