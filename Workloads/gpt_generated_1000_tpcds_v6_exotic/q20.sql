WITH base_agg AS (
  SELECT
    t.t_hour,
    t.t_am_pm,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE t.t_hour BETWEEN 8 AND 20
    AND t.t_am_pm = 'PM'
    AND hd.hd_vehicle_count >= 0
    AND hd.hd_dep_count <= 6
    AND ib.ib_lower_bound >= 20000
    AND ib.ib_upper_bound <= 80000
    AND ss.ss_quantity > 1
    AND ss.ss_ext_discount_amt > 0
  GROUP BY t.t_hour, t.t_am_pm, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),

filtered_agg AS (
  SELECT *
  FROM base_agg
  WHERE total_sales > (SELECT AVG(total_sales) FROM base_agg)
    AND EXISTS (
      SELECT 1 FROM income_band ib2
      WHERE ib2.ib_income_band_sk = base_agg.ib_income_band_sk
        AND ib2.ib_upper_bound > 60000
    )
),

union_bands AS (
  SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 90000
  UNION
  SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound < 25000
)

SELECT
  fa.t_hour,
  fa.t_am_pm,
  fa.ib_income_band_sk,
  fa.ib_lower_bound,
  fa.ib_upper_bound,
  fa.total_sales,
  fa.total_discount,
  fa.sales_cnt,
  (fa.total_discount / NULLIF(fa.sales_cnt, 0)) AS avg_discount_per_sale
FROM filtered_agg fa
WHERE fa.ib_income_band_sk IN (SELECT ib_income_band_sk FROM union_bands)
GROUP BY fa.t_hour, fa.t_am_pm, fa.ib_income_band_sk, fa.ib_lower_bound, fa.ib_upper_bound,
         fa.total_sales, fa.total_discount, fa.sales_cnt
HAVING SUM(fa.total_sales) > 100000
ORDER BY fa.total_sales DESC
LIMIT 100
