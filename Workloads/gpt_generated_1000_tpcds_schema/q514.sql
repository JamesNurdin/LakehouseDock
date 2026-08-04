SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       hd.hd_vehicle_count
FROM tpcds.customer c
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_birth_month = 5
  AND hd.hd_income_band_sk IN (5, 10, 12)
ORDER BY c.c_customer_id
LIMIT 100
