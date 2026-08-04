WITH high_sales AS (
  SELECT
    ss.ss_hdemo_sk AS hd_demo_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales
  FROM store_sales ss
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_lower_bound >= 120001
    AND ib.ib_upper_bound <= 200000
  GROUP BY ss.ss_hdemo_sk
),
low_sales AS (
  SELECT
    ss.ss_hdemo_sk AS hd_demo_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales
  FROM store_sales ss
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_upper_bound <= 50000
  GROUP BY ss.ss_hdemo_sk
),
union_sales AS (
  SELECT hd_demo_sk, total_sales FROM high_sales
  UNION
  SELECT hd_demo_sk, total_sales FROM low_sales
),
excluded_sales AS (
  SELECT
    hd.hd_demo_sk,
    CAST(0 AS decimal(7,2)) AS total_sales
  FROM household_demographics hd
  WHERE hd.hd_vehicle_count < 0
),
filtered_sales AS (
  SELECT hd_demo_sk, total_sales FROM union_sales
  EXCEPT
  SELECT hd_demo_sk, total_sales FROM excluded_sales
),
buy_potential_dim AS (
  SELECT DISTINCT hd_buy_potential FROM household_demographics
)
SELECT
  d.hd_buy_potential,
  f.hd_demo_sk,
  f.total_sales
FROM filtered_sales f
LEFT JOIN household_demographics hd ON f.hd_demo_sk = hd.hd_demo_sk
FULL OUTER JOIN buy_potential_dim d ON hd.hd_buy_potential = d.hd_buy_potential
ORDER BY f.total_sales DESC
LIMIT 100
