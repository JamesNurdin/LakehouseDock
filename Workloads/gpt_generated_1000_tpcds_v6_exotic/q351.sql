/* goal: Compare the number of preferred vs. non‑preferred customers across birth countries and vehicle ownership levels, segmented by income band criteria, using a UNION ALL to combine the two cohorts. */
SELECT
  birth_country,
  vehicle_count,
  preferred_flag,
  customer_cnt
FROM (
  SELECT
    c.c_birth_country AS birth_country,
    hd.hd_vehicle_count AS vehicle_count,
    c.c_preferred_cust_flag AS preferred_flag,
    COUNT(*) AS customer_cnt
  FROM tpcds.customer AS c
  JOIN tpcds.household_demographics AS hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND hd.hd_income_band_sk IN (3, 14)
    AND hd.hd_vehicle_count >= 1
  GROUP BY
    c.c_birth_country,
    hd.hd_vehicle_count,
    c.c_preferred_cust_flag

  UNION ALL

  SELECT
    c.c_birth_country AS birth_country,
    hd.hd_vehicle_count AS vehicle_count,
    c.c_preferred_cust_flag AS preferred_flag,
    COUNT(*) AS customer_cnt
  FROM tpcds.customer AS c
  JOIN tpcds.household_demographics AS hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_preferred_cust_flag = 'N'
    AND hd.hd_income_band_sk IN (18, 19)
    AND hd.hd_vehicle_count = 0
  GROUP BY
    c.c_birth_country,
    hd.hd_vehicle_count,
    c.c_preferred_cust_flag
) AS combined
ORDER BY
  birth_country ASC,
  vehicle_count DESC,
  customer_cnt DESC
LIMIT 100
