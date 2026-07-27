SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    hd.hd_vehicle_count
FROM tpcds.customer AS c
JOIN tpcds.household_demographics AS hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
  AND c.c_birth_year = 1975
ORDER BY hd.hd_vehicle_count DESC, c.c_customer_id
