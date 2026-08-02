SELECT c.c_customer_id, c.c_first_name, c.c_last_name, h.hd_buy_potential, h.hd_vehicle_count
FROM tpcds.customer c
JOIN tpcds.household_demographics h
  ON c.c_current_hdemo_sk = h.hd_demo_sk
WHERE c.c_birth_year >= 1960
  AND h.hd_income_band_sk = 12
LIMIT 100
