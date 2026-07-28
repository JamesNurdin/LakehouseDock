SELECT DISTINCT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       hd.hd_buy_potential,
       hd.hd_vehicle_count
FROM tpcds.customer c
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
  AND c.c_last_review_date > 2452450
ORDER BY c.c_last_name ASC
LIMIT 100
